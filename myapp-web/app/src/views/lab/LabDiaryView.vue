<template>
  <div class="max-w-4xl mx-auto px-6 py-10">
    <div class="mb-8 flex items-center justify-between">
      <div>
        <h2 class="text-xl font-bold">日記</h2>
        <p class="text-sm text-white/60 mt-1">カレンダーから日付を選んで、日記・メモ・タスクを記録する</p>
      </div>
      <div class="flex items-center gap-3">
        <button type="button" class="text-white/70 hover:text-white transition-colors" @click="changeMonth(-1)">
          ◀
        </button>
        <div class="text-sm font-medium w-28 text-center">{{ year }}年{{ month }}月</div>
        <button type="button" class="text-white/70 hover:text-white transition-colors" @click="changeMonth(1)">
          ▶
        </button>
      </div>
    </div>

    <div v-if="errorMsg" class="mb-6 bg-red-500/10 border border-red-500/30 text-red-300 rounded-xl p-4 text-sm">
      {{ errorMsg }}
    </div>

    <div v-if="loading" class="text-center text-white/60 py-10 text-sm">読み込み中...</div>

    <div v-else class="grid grid-cols-7 gap-1">
      <div v-for="w in weekdays" :key="w" class="text-xs text-white/60 text-center py-2">{{ w }}</div>
      <button
        v-for="day in calendarDays"
        :key="day.iso"
        type="button"
        class="relative min-h-[72px] rounded-lg border p-1.5 flex flex-col items-start gap-0.5 overflow-hidden text-left transition-colors"
        :class="dayStyle(day)"
        @click="selectDay(day.iso)"
      >
        <span class="text-xs">{{ day.date.getDate() }}</span>
        <img
          v-if="day.diary?.photos?.length"
          :src="day.diary.photos[0].url"
          alt=""
          class="mt-0.5 h-8 w-full rounded object-cover"
        />
        <span v-else-if="day.diary" class="w-full truncate text-[10px] text-primary">
          📔 {{ day.diary.title || day.diary.content }}
        </span>
        <span v-for="memo in day.memos.slice(0, 1)" :key="memo.id" class="w-full truncate text-[10px] text-indigo-300">
          📝 {{ memo.title || memo.content || 'メモ' }}
        </span>
        <span v-if="day.memos.length > 1" class="w-full truncate text-[10px] text-white/50">
          メモ他{{ day.memos.length - 1 }}件
        </span>
        <span v-for="task in day.tasks.slice(0, 2)" :key="task.id" class="w-full truncate text-[10px] text-yellow-400">
          📌 {{ task.title }}
        </span>
        <span v-if="day.tasks.length > 2" class="w-full truncate text-[10px] text-white/60">
          他{{ day.tasks.length - 2 }}件
        </span>
      </button>
    </div>

    <div
      v-if="showDialog"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4"
      @click.self="closeDialog"
    >
      <div class="w-full max-w-2xl max-h-[90vh] overflow-y-auto rounded-2xl border border-white/10 bg-[#0c1220] p-8 space-y-5">
        <div class="flex items-center justify-between">
          <h3 class="font-semibold text-base">{{ selectedDate }}</h3>
          <button type="button" class="text-white/60 hover:text-white transition-colors" @click="closeDialog">
            ✕
          </button>
        </div>

        <div>
          <label class="block text-xs text-white/60 mb-1">タイトル</label>
          <input
            v-model="form.title"
            type="text"
            :disabled="!canWrite('diary')"
            class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2.5 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50"
          />
        </div>

        <div>
          <label class="block text-xs text-white/60 mb-1">本文</label>
          <textarea
            v-model="form.content"
            rows="8"
            :disabled="!canWrite('diary')"
            class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2.5 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50"
          />
        </div>

        <div>
          <label class="block text-xs text-white/60 mb-2">写真</label>
          <div class="flex flex-wrap gap-2 mb-3">
            <button
              v-for="photo in keptPhotos"
              :key="photo.id"
              type="button"
              class="relative h-20 w-20"
              :disabled="!canWrite('diary')"
              @click="removedPhotoIds.push(photo.id)"
            >
              <img :src="photo.url" alt="" class="h-20 w-20 rounded-lg object-cover border border-white/10" />
              <span v-if="canWrite('diary')" class="absolute top-0.5 right-0.5 text-[10px] bg-black/70 rounded px-1">削除</span>
            </button>
            <button
              v-for="(file, index) in pendingFiles"
              :key="file.name + index"
              type="button"
              class="relative h-20 w-20"
              @click="removePending(index)"
            >
              <img :src="pendingUrls[index]" alt="" class="h-20 w-20 rounded-lg object-cover border border-white/10" />
              <span class="absolute top-0.5 right-0.5 text-[10px] bg-black/70 rounded px-1">取消</span>
            </button>
          </div>
          <div v-if="canWrite('diary')" class="flex flex-wrap gap-2">
            <button type="button" class="text-xs px-3 py-1.5 rounded-full border border-white/20 hover:border-white/40" @click="cameraInput?.click()">
              カメラ
            </button>
            <button type="button" class="text-xs px-3 py-1.5 rounded-full border border-white/20 hover:border-white/40" @click="fileInput?.click()">
              ファイルを選択
            </button>
            <button
              v-if="keptPhotos.length || pendingFiles.length"
              type="button"
              class="text-xs px-3 py-1.5 rounded-full border border-white/20 text-white/60 hover:text-white"
              @click="clearPendingPhotos"
            >
              追加分を取り消す
            </button>
          </div>
          <input ref="cameraInput" type="file" accept="image/*" capture="environment" class="hidden" @change="onPickPhotos" />
          <input ref="fileInput" type="file" accept="image/*" multiple class="hidden" @change="onPickPhotos" />
        </div>

        <div class="flex items-center justify-between pt-2">
          <button
            v-if="selectedDiary && canWrite('diary')"
            type="button"
            class="text-xs text-red-400/70 hover:text-red-400 transition-colors"
            @click="removeDiary"
          >
            削除
          </button>
          <span v-else />
          <button
            v-if="canWrite('diary')"
            type="button"
            class="text-sm px-4 py-2 rounded-full bg-primary text-black font-medium hover:opacity-90 transition-opacity disabled:opacity-50"
            :disabled="(!form.content && !keptPhotos.length && !pendingFiles.length) || saving"
            @click="saveDiary"
          >
            {{ selectedDiary ? '更新する' : '保存する' }}
          </button>
        </div>

        <div v-if="canRead('memo')" class="border-t border-white/10 pt-4 space-y-3">
          <div class="flex items-center justify-between">
            <h4 class="text-sm font-medium">メモ</h4>
            <button
              v-if="canWrite('memo') && editingMemoKey === null"
              type="button"
              class="text-xs px-3 py-1.5 rounded-full border border-white/20 hover:border-white/40"
              @click="startNewMemo"
            >
              追加
            </button>
          </div>
          <p v-if="selectedMemos.length === 0 && editingMemoKey === null" class="text-xs text-white/40">この日のメモはありません</p>
          <div v-for="memo in selectedMemos" :key="memo.id" class="rounded-xl border border-white/10 p-3 space-y-2">
            <template v-if="editingMemoKey === memo.id">
              <input
                v-model="memoForm.title"
                type="text"
                placeholder="タイトル"
                class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm focus:outline-none focus:border-primary/60"
              />
              <textarea
                v-model="memoForm.content"
                rows="4"
                placeholder="本文"
                class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm focus:outline-none focus:border-primary/60"
              />
              <div class="flex justify-end gap-2">
                <button type="button" class="text-xs text-white/60 hover:text-white" @click="editingMemoKey = null">キャンセル</button>
                <button
                  type="button"
                  class="text-xs px-3 py-1.5 rounded-full bg-primary text-black font-medium disabled:opacity-50"
                  :disabled="memoSaving || (!memoForm.title && !memoForm.content)"
                  @click="saveMemo"
                >
                  保存
                </button>
              </div>
            </template>
            <template v-else>
              <div class="flex items-start justify-between gap-3">
                <div class="min-w-0">
                  <p class="text-sm font-medium truncate">{{ memo.title || '無題' }}</p>
                  <p class="text-xs text-white/60 whitespace-pre-wrap">{{ memo.content }}</p>
                </div>
                <div v-if="canWrite('memo')" class="flex shrink-0 gap-2 text-xs">
                  <button type="button" class="text-white/60 hover:text-white" @click="startEditMemo(memo)">編集</button>
                  <button type="button" class="text-red-400/70 hover:text-red-400" @click="removeMemo(memo)">削除</button>
                </div>
              </div>
            </template>
          </div>
          <div v-if="editingMemoKey === 'new'" class="rounded-xl border border-white/10 p-3 space-y-2">
            <input
              v-model="memoForm.title"
              type="text"
              placeholder="タイトル"
              class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm focus:outline-none focus:border-primary/60"
            />
            <textarea
              v-model="memoForm.content"
              rows="4"
              placeholder="本文"
              class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm focus:outline-none focus:border-primary/60"
            />
            <div class="flex justify-end gap-2">
              <button type="button" class="text-xs text-white/60 hover:text-white" @click="editingMemoKey = null">キャンセル</button>
              <button
                type="button"
                class="text-xs px-3 py-1.5 rounded-full bg-primary text-black font-medium disabled:opacity-50"
                :disabled="memoSaving || (!memoForm.title && !memoForm.content)"
                @click="saveMemo"
              >
                保存
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import {
  createDiary,
  createMemo,
  deleteDiary,
  deleteDiaryPhoto,
  deleteMemo,
  fetchDiaries,
  fetchMemos,
  fetchTasks,
  updateDiary,
  updateMemo,
  uploadDiaryPhoto,
  type DiaryEntry,
  type DiaryPhoto,
  type LabTask,
  type Memo,
} from '../../lib/api'
import { canRead, canWrite } from '../../lib/permissions'

const weekdays = ['日', '月', '火', '水', '木', '金', '土']

const today = new Date()
const year = ref(today.getFullYear())
const month = ref(today.getMonth() + 1)

const diaries = ref<DiaryEntry[]>([])
const memos = ref<Memo[]>([])
const tasks = ref<LabTask[]>([])
const loading = ref(true)
const saving = ref(false)
const errorMsg = ref('')
const selectedDate = ref<string>(toIso(today))
const showDialog = ref(false)

const form = reactive({ title: '', content: '' })
const memoForm = reactive({ title: '', content: '' })
const editingMemoKey = ref<number | 'new' | null>(null)
const memoSaving = ref(false)
const cameraInput = ref<HTMLInputElement | null>(null)
const fileInput = ref<HTMLInputElement | null>(null)
const pendingFiles = ref<File[]>([])
const pendingUrls = ref<string[]>([])
const removedPhotoIds = ref<number[]>([])

const keptPhotos = computed<DiaryPhoto[]>(() =>
  (selectedDiary.value?.photos ?? []).filter((photo) => !removedPhotoIds.value.includes(photo.id)),
)

interface CalendarDay {
  date: Date
  iso: string
  inMonth: boolean
  diary: DiaryEntry | undefined
  memos: Memo[]
  tasks: LabTask[]
}

function memoDay(memo: Memo): string {
  return memo.date || memo.created_at.slice(0, 10)
}

function toIso(date: Date): string {
  const y = date.getFullYear()
  const m = String(date.getMonth() + 1).padStart(2, '0')
  const d = String(date.getDate()).padStart(2, '0')
  return `${y}-${m}-${d}`
}

const selectedDiary = computed<DiaryEntry | undefined>(() =>
  diaries.value.find((d) => d.date === selectedDate.value),
)

const selectedMemos = computed(() => memos.value.filter((memo) => memoDay(memo) === selectedDate.value))

const calendarDays = computed<CalendarDay[]>(() => {
  const firstOfMonth = new Date(year.value, month.value - 1, 1)
  const startOffset = firstOfMonth.getDay()
  const gridStart = new Date(year.value, month.value - 1, 1 - startOffset)

  const days: CalendarDay[] = []
  for (let i = 0; i < 42; i++) {
    const date = new Date(gridStart)
    date.setDate(gridStart.getDate() + i)
    const iso = toIso(date)
    days.push({
      date,
      iso,
      inMonth: date.getMonth() === month.value - 1,
      diary: diaries.value.find((d) => d.date === iso),
      memos: memos.value.filter((memo) => memoDay(memo) === iso),
      tasks: tasks.value.filter((t) => t.due_date === iso),
    })
  }
  return days
})

function dayStyle(day: CalendarDay): string {
  const classes: string[] = []
  classes.push(day.inMonth ? 'text-white' : 'text-white/45')
  if (day.iso === selectedDate.value && showDialog.value) {
    classes.push('border-primary bg-primary/10')
  } else {
    classes.push('border-white/10 hover:border-white/30')
  }
  return classes.join(' ')
}

function clearPendingPhotos() {
  pendingUrls.value.forEach((url) => URL.revokeObjectURL(url))
  pendingFiles.value = []
  pendingUrls.value = []
}

function applySelectedToForm() {
  form.title = selectedDiary.value?.title ?? ''
  form.content = selectedDiary.value?.content ?? ''
  clearPendingPhotos()
  removedPhotoIds.value = []
}

function removePending(index: number) {
  URL.revokeObjectURL(pendingUrls.value[index])
  pendingFiles.value.splice(index, 1)
  pendingUrls.value.splice(index, 1)
}

async function compressImage(file: File): Promise<File> {
  try {
    const bitmap = await createImageBitmap(file)
    const maxEdge = 1600
    const scale = Math.min(1, maxEdge / Math.max(bitmap.width, bitmap.height))
    const width = Math.max(1, Math.round(bitmap.width * scale))
    const height = Math.max(1, Math.round(bitmap.height * scale))
    const canvas = document.createElement('canvas')
    canvas.width = width
    canvas.height = height
    const ctx = canvas.getContext('2d')
    if (!ctx) return file
    ctx.drawImage(bitmap, 0, 0, width, height)
    bitmap.close()
    const blob = await new Promise<Blob | null>((resolve) => {
      canvas.toBlob(resolve, 'image/jpeg', 0.72)
    })
    if (!blob) return file
    const name = file.name.replace(/\.[^.]+$/, '') || 'photo'
    return new File([blob], `${name}.jpg`, { type: 'image/jpeg' })
  } catch {
    return file
  }
}

async function onPickPhotos(event: Event) {
  const input = event.target as HTMLInputElement
  const files = Array.from(input.files ?? [])
  input.value = ''
  for (const file of files) {
    const compressed = await compressImage(file)
    pendingFiles.value.push(compressed)
    pendingUrls.value.push(URL.createObjectURL(compressed))
  }
}

function selectDay(iso: string) {
  selectedDate.value = iso
  applySelectedToForm()
  editingMemoKey.value = null
  showDialog.value = true
}

function startNewMemo() {
  memoForm.title = ''
  memoForm.content = ''
  editingMemoKey.value = 'new'
}

function startEditMemo(memo: Memo) {
  memoForm.title = memo.title
  memoForm.content = memo.content
  editingMemoKey.value = memo.id
}

function closeDialog() {
  showDialog.value = false
}

async function loadCalendarData() {
  loading.value = true
  errorMsg.value = ''
  try {
    const [diaryData, taskData, memoData] = await Promise.all([
      fetchDiaries(year.value, month.value),
      fetchTasks(),
      canRead('memo') ? fetchMemos().catch(() => [] as Memo[]) : Promise.resolve([] as Memo[]),
    ])
    diaries.value = diaryData
    tasks.value = taskData
    memos.value = memoData
    applySelectedToForm()
  } catch {
    errorMsg.value = 'データの取得に失敗しました。'
  } finally {
    loading.value = false
  }
}

function changeMonth(diff: number) {
  let newMonth = month.value + diff
  let newYear = year.value
  if (newMonth < 1) {
    newMonth = 12
    newYear -= 1
  } else if (newMonth > 12) {
    newMonth = 1
    newYear += 1
  }
  month.value = newMonth
  year.value = newYear
}

watch([year, month], loadCalendarData)

async function saveDiary() {
  saving.value = true
  errorMsg.value = ''
  try {
    let entry: DiaryEntry
    if (selectedDiary.value) {
      entry = await updateDiary(selectedDiary.value.id, {
        date: selectedDate.value,
        title: form.title,
        content: form.content,
      })
    } else {
      entry = await createDiary({
        date: selectedDate.value,
        title: form.title,
        content: form.content,
      })
    }
    for (const photoId of removedPhotoIds.value) {
      await deleteDiaryPhoto(entry.id, photoId)
    }
    for (const file of pendingFiles.value) {
      await uploadDiaryPhoto(entry.id, file)
    }
    await loadCalendarData()
    showDialog.value = false
  } catch {
    errorMsg.value = '保存に失敗しました。'
  } finally {
    saving.value = false
  }
}

async function saveMemo() {
  memoSaving.value = true
  errorMsg.value = ''
  try {
    const input = { date: selectedDate.value, title: memoForm.title, content: memoForm.content }
    if (editingMemoKey.value === 'new') {
      await createMemo(input)
    } else if (typeof editingMemoKey.value === 'number') {
      await updateMemo(editingMemoKey.value, input)
    }
    editingMemoKey.value = null
    memos.value = canRead('memo') ? await fetchMemos() : []
  } catch {
    errorMsg.value = 'メモの保存に失敗しました。'
  } finally {
    memoSaving.value = false
  }
}

async function removeMemo(memo: Memo) {
  if (!confirm(`「${memo.title || '無題'}」を削除しますか？`)) return
  try {
    await deleteMemo(memo.id)
    memos.value = memos.value.filter((item) => item.id !== memo.id)
    if (editingMemoKey.value === memo.id) editingMemoKey.value = null
  } catch {
    errorMsg.value = 'メモの削除に失敗しました。'
  }
}

async function removeDiary() {
  if (!selectedDiary.value) return
  if (!confirm(`${selectedDate.value} の日記を削除しますか？`)) return
  try {
    await deleteDiary(selectedDiary.value.id)
    diaries.value = diaries.value.filter((d) => d.id !== selectedDiary.value!.id)
    applySelectedToForm()
    showDialog.value = false
  } catch {
    errorMsg.value = '削除に失敗しました。'
  }
}

onMounted(loadCalendarData)
</script>
