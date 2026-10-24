<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4" @click.self="emit('close')">
    <div class="w-full max-w-4xl max-h-[92vh] overflow-y-auto rounded-2xl border border-white/10 bg-[#0c1220] p-6 md:p-8">
      <div class="mb-5 flex items-center justify-between">
        <h3 class="font-semibold text-base">{{ task ? 'タスクを編集' : 'タスクを新規作成' }}</h3>
        <button type="button" class="text-white/60 hover:text-white transition-colors" @click="emit('close')">✕</button>
      </div>

      <div class="grid gap-6 md:grid-cols-[1fr_300px]">
        <!-- 左: 内容 -->
        <div class="space-y-4">
          <div>
            <label class="block text-xs text-white/60 mb-1">タイトル</label>
            <input v-model="form.title" type="text" :disabled="readonly" :class="inputClass" class="w-full" />
          </div>
          <div>
            <label class="block text-xs text-white/60 mb-1">詳細</label>
            <textarea
              v-model="form.description"
              rows="8"
              :disabled="readonly"
              :class="inputClass"
              class="w-full"
              placeholder="詳細。画像は Ctrl+V で貼り付けられます"
            />
          </div>

          <div>
            <label class="block text-xs text-white/60 mb-2">写真</label>
            <div class="flex flex-wrap gap-2 mb-3">
              <div v-for="photo in keptPhotos" :key="photo.id" class="relative h-20 w-20">
                <img :src="photo.url" alt="" class="h-20 w-20 rounded-lg object-cover border border-white/10" />
                <button
                  v-if="!readonly"
                  type="button"
                  class="absolute top-0.5 right-0.5 text-[10px] bg-black/70 hover:bg-black rounded px-1"
                  @click="removedPhotoIds.push(photo.id)"
                >
                  削除
                </button>
              </div>
              <div v-for="(file, index) in pendingFiles" :key="file.name + index" class="relative h-20 w-20">
                <img :src="pendingUrls[index]" alt="" class="h-20 w-20 rounded-lg object-cover border border-white/10" />
                <button
                  v-if="!readonly"
                  type="button"
                  class="absolute top-0.5 right-0.5 text-[10px] bg-black/70 hover:bg-black rounded px-1"
                  @click="removePending(index)"
                >
                  取消
                </button>
              </div>
            </div>
            <div v-if="!readonly" class="flex flex-wrap gap-2">
              <button type="button" class="text-xs px-3 py-1.5 rounded-full border border-white/20 hover:border-white/40" @click="fileInput?.click()">
                ファイルを選択
              </button>
              <button type="button" class="text-xs px-3 py-1.5 rounded-full border border-white/20 hover:border-white/40" @click="cameraInput?.click()">
                カメラ
              </button>
              <span class="text-[11px] text-white/40 self-center">Ctrl+V で画像を貼り付け</span>
            </div>
            <input ref="cameraInput" type="file" accept="image/*" capture="environment" class="hidden" @change="onPickPhotos" />
            <input ref="fileInput" type="file" accept="image/*" multiple class="hidden" @change="onPickPhotos" />
          </div>

          <div>
            <label class="block text-xs text-white/60 mb-1">先行タスク（完了後に開始）</label>
            <div class="flex flex-wrap gap-2 mb-2">
              <span
                v-for="dep in dependencyTasks"
                :key="dep.id"
                class="inline-flex items-center gap-1 text-xs px-2.5 py-1 rounded-full bg-white/10 text-white/80"
              >
                {{ dep.title }}
                <button v-if="!readonly" type="button" class="text-white/50 hover:text-white" @click="removeDependency(dep.id)">✕</button>
              </span>
              <span v-if="dependencyTasks.length === 0" class="text-xs text-white/40">なし</span>
            </div>
            <select
              v-if="!readonly"
              :class="inputClass"
              class="w-full"
              @change="onDependencySelect"
            >
              <option value="">＋ 先行タスクを追加</option>
              <option v-for="opt in dependencyCandidates" :key="opt.id" :value="opt.id">{{ opt.title }}</option>
            </select>
            <p v-if="dependentTasks.length" class="mt-2 text-xs text-white/50">
              後続タスク: {{ dependentTasks.map((t) => t.title).join('、') }}
            </p>
          </div>
        </div>

        <!-- 右: 属性 -->
        <div class="space-y-4">
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-xs text-white/60 mb-1">ステータス</label>
              <select v-model="form.status" :disabled="readonly" :class="inputClass" class="w-full">
                <option v-for="opt in STATUS_OPTIONS" :key="opt.value" :value="opt.value">{{ opt.label }}</option>
              </select>
            </div>
            <div>
              <label class="block text-xs text-white/60 mb-1">優先度</label>
              <select v-model="form.priority" :disabled="readonly" :class="inputClass" class="w-full">
                <option v-for="opt in PRIORITY_OPTIONS" :key="opt.value" :value="opt.value">{{ opt.label }}</option>
              </select>
            </div>
          </div>

          <div>
            <label class="block text-xs text-white/60 mb-1">親タスク</label>
            <select v-model="form.parent" :disabled="readonly" :class="inputClass" class="w-full">
              <option :value="null">（なし）</option>
              <option v-for="row in parentCandidates" :key="row.task.id" :value="row.task.id">
                {{ '　'.repeat(row.level) }}{{ row.wbsNo }} {{ row.task.title }}
              </option>
            </select>
          </div>

          <div>
            <label class="block text-xs text-white/60 mb-1">開始日</label>
            <input v-model="form.start_date" type="date" :disabled="readonly" :class="inputClass" class="w-full" @change="onStartChange" />
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-xs text-white/60 mb-1">期間（稼働日）</label>
              <input
                v-model="durationInput"
                type="number"
                min="0"
                max="999"
                step="0.25"
                :disabled="readonly"
                :class="inputClass"
                class="w-full"
                @change="onDurationChange"
              />
            </div>
            <div>
              <label class="block text-xs text-white/60 mb-1">終了日</label>
              <input v-model="form.due_date" type="date" :disabled="readonly" :class="inputClass" class="w-full" @change="onDueChange" />
            </div>
          </div>
          <p class="text-[11px] text-white/40 -mt-2">期間は土日を除いた日数。開始日・期間・終了日は連動します。</p>

          <div>
            <label class="block text-xs text-white/60 mb-1">進捗 {{ form.progress }}%</label>
            <input v-model.number="form.progress" type="range" min="0" max="100" step="5" :disabled="readonly" class="w-full accent-primary" />
          </div>

          <label class="flex items-start gap-2 cursor-pointer select-none">
            <input
              v-model="form.is_shared"
              type="checkbox"
              class="mt-0.5 accent-primary"
              :disabled="readonly || (task != null && !task.is_mine)"
            />
            <span>
              <span class="block text-xs text-white/80">他のLabユーザーと共有</span>
              <span class="block text-[11px] text-white/40 mt-0.5">
                共有すると、親・子・先行/後続に紐づくタスクも相手に見えます
              </span>
            </span>
          </label>

          <p v-if="task && !task.is_mine" class="text-xs text-amber-200/80">
            {{ task.owner_username }} さんの共有タスク（閲覧のみ）
          </p>
          <p v-if="dateError" class="text-xs text-red-300">{{ dateError }}</p>
        </div>
      </div>

      <div class="mt-6 flex items-center justify-between">
        <button
          v-if="task && !readonly"
          type="button"
          class="text-xs text-red-400/70 hover:text-red-400 transition-colors"
          @click="emit('delete', task)"
        >
          削除
        </button>
        <span v-else />
        <div class="flex gap-3">
          <button
            type="button"
            class="text-sm px-4 py-2 rounded-full border border-white/20 text-white/80 hover:text-white transition-colors"
            @click="emit('close')"
          >
            {{ readonly ? '閉じる' : 'キャンセル' }}
          </button>
          <button
            v-if="!readonly"
            type="button"
            class="text-sm px-4 py-2 rounded-full bg-primary text-black font-medium hover:opacity-90 transition-opacity disabled:opacity-50"
            :disabled="!form.title || !!dateError || saving"
            @click="submit"
          >
            {{ task ? '更新する' : '作成する' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, reactive, ref } from 'vue'
import type { DiaryPhoto, LabTask, LabTaskInput } from '../../lib/api'
import { compressImage, filesFromClipboard } from '../../lib/labImages'
import {
  PRIORITY_OPTIONS,
  STATUS_OPTIONS,
  buildTaskRows,
  countWorkingDays,
  descendantIds,
  endDateFromDuration,
  formatDuration,
} from '../../lib/tasks'

export type TaskFormSubmit = {
  input: LabTaskInput
  pendingFiles: File[]
  removedPhotoIds: number[]
}

const props = defineProps<{
  task: LabTask | null
  tasks: LabTask[]
  defaults?: Partial<LabTaskInput>
  readonly?: boolean
  saving?: boolean
}>()

const emit = defineEmits<{
  close: []
  submit: [payload: TaskFormSubmit]
  delete: [task: LabTask]
}>()

const inputClass =
  'rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50'

const source = props.task
const form = reactive<LabTaskInput>({
  title: source?.title ?? '',
  description: source?.description ?? '',
  status: source?.status ?? 'todo',
  priority: source?.priority ?? 'medium',
  start_date: source?.start_date ?? null,
  due_date: source?.due_date ?? null,
  duration_days: source?.duration_days ?? null,
  progress: source?.progress ?? 0,
  parent: source?.parent ?? null,
  order: source?.order ?? 0,
  dependencies: [...(source?.dependencies ?? [])],
  is_shared: source?.is_shared ?? false,
  ...props.defaults,
})

const durationInput = ref(form.duration_days != null ? formatDuration(Number(form.duration_days)) : '')
const cameraInput = ref<HTMLInputElement | null>(null)
const fileInput = ref<HTMLInputElement | null>(null)
const pendingFiles = ref<File[]>([])
const pendingUrls = ref<string[]>([])
const removedPhotoIds = ref<number[]>([])

const keptPhotos = computed<DiaryPhoto[]>(() =>
  (source?.photos ?? []).filter((photo) => !removedPhotoIds.value.includes(photo.id)),
)

const dateError = computed(() => {
  if (form.start_date && form.due_date && form.due_date < form.start_date) return '終了日は開始日以降にしてください。'
  return ''
})

const parentCandidates = computed(() => {
  const excluded = source ? descendantIds(props.tasks, source.id) : new Set<number>()
  return buildTaskRows(props.tasks).filter((row) => !excluded.has(row.task.id))
})

const dependencyTasks = computed(() => props.tasks.filter((t) => form.dependencies.includes(t.id)))
const dependencyCandidates = computed(() =>
  props.tasks.filter((t) => t.id !== source?.id && !form.dependencies.includes(t.id)),
)
const dependentTasks = computed(() => (source ? props.tasks.filter((t) => t.dependencies.includes(source.id)) : []))

function onDependencySelect(event: Event) {
  const select = event.target as HTMLSelectElement
  const id = Number(select.value)
  if (id && !form.dependencies.includes(id)) form.dependencies.push(id)
  select.value = ''
}

function removeDependency(id: number) {
  form.dependencies = form.dependencies.filter((d) => d !== id)
}

function removePending(index: number) {
  URL.revokeObjectURL(pendingUrls.value[index])
  pendingFiles.value.splice(index, 1)
  pendingUrls.value.splice(index, 1)
}

async function addFiles(files: File[]) {
  for (const file of files) {
    const compressed = await compressImage(file)
    pendingFiles.value.push(compressed)
    pendingUrls.value.push(URL.createObjectURL(compressed))
  }
}

async function onPickPhotos(event: Event) {
  const input = event.target as HTMLInputElement
  const files = Array.from(input.files ?? [])
  input.value = ''
  await addFiles(files)
}

async function onPaste(event: ClipboardEvent) {
  if (props.readonly) return
  const files = filesFromClipboard(event)
  if (!files.length) return
  event.preventDefault()
  await addFiles(files)
}

function currentDuration(): number | null {
  const value = parseFloat(durationInput.value)
  return Number.isFinite(value) && value > 0 ? value : null
}

function onStartChange() {
  if (!form.start_date) return
  const duration = currentDuration()
  if (duration != null) {
    form.due_date = endDateFromDuration(form.start_date, duration)
  } else if (form.due_date && form.due_date >= form.start_date) {
    durationInput.value = String(countWorkingDays(form.start_date, form.due_date))
  }
}

function onDurationChange() {
  const duration = currentDuration()
  if (duration != null && form.start_date) form.due_date = endDateFromDuration(form.start_date, duration)
}

function onDueChange() {
  if (form.start_date && form.due_date && form.due_date >= form.start_date) {
    durationInput.value = String(countWorkingDays(form.start_date, form.due_date))
  }
}

function submit() {
  const duration = currentDuration()
  emit('submit', {
    input: { ...form, duration_days: duration != null ? duration.toFixed(2) : null },
    pendingFiles: [...pendingFiles.value],
    removedPhotoIds: [...removedPhotoIds.value],
  })
}

onMounted(() => window.addEventListener('paste', onPaste))
onBeforeUnmount(() => {
  window.removeEventListener('paste', onPaste)
  pendingUrls.value.forEach((url) => URL.revokeObjectURL(url))
})
</script>
