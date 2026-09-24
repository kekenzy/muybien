<template>
  <div>
    <div class="mb-4 flex justify-end gap-1 text-xs">
      <button
        v-for="mode in viewModes"
        :key="mode.value"
        type="button"
        class="px-3 py-1.5 rounded-full border transition-colors"
        :class="viewMode === mode.value ? 'bg-white/10 border-white/30 text-white' : 'border-white/10 text-white/50 hover:text-white'"
        @click="viewMode = mode.value"
      >
        {{ mode.label }}
      </button>
    </div>

    <!-- カンバン -->
    <div v-if="viewMode === 'board'" class="overflow-x-auto pb-2">
      <div class="grid grid-cols-6 gap-3 min-w-[1080px]">
        <div
          v-for="column in columns"
          :key="column.value"
          class="rounded-2xl border bg-white/[0.03] p-2 transition-colors"
          :class="dragOverStatus === column.value ? 'border-primary/60 bg-primary/5' : 'border-white/10'"
          @dragover.prevent="dragOverStatus = column.value"
          @dragleave="onDragLeave($event, column.value)"
          @drop.prevent="onDrop(column.value)"
        >
          <div class="flex items-center gap-2 px-2 py-1.5 text-xs font-medium text-white/80">
            <span class="h-2 w-2 rounded-full" :class="column.dot" />
            {{ column.label }}
            <span class="ml-auto text-white/40">{{ column.tasks.length }}</span>
          </div>
          <div class="mt-1 space-y-2 min-h-[80px]">
            <div
              v-for="task in column.tasks"
              :key="task.id"
              :draggable="canEdit"
              class="rounded-xl border border-white/10 bg-[#0c1220] p-3 cursor-pointer hover:border-white/30 transition-colors"
              :class="draggingId === task.id ? 'opacity-40' : ''"
              @dragstart="onDragStart($event, task)"
              @dragend="draggingId = null; dragOverStatus = null"
              @click="emit('open', task)"
            >
              <div class="flex items-center gap-1.5 mb-1.5">
                <span class="text-[10px] px-1.5 py-0.5 rounded" :class="priorityMeta(task.priority).badge">
                  {{ priorityMeta(task.priority).label }}
                </span>
                <span v-if="parentTitle(task)" class="text-[10px] text-white/40 truncate">↳ {{ parentTitle(task) }}</span>
              </div>
              <p class="text-sm font-medium leading-snug break-words" :class="task.status === 'done' ? 'line-through text-white/50' : ''">
                {{ task.title }}
              </p>
              <p v-if="task.description" class="mt-1 text-xs text-white/50 line-clamp-2 whitespace-pre-line">{{ task.description }}</p>
              <div class="mt-2 flex items-center justify-between text-[11px]">
                <span :class="isOverdue(task) ? 'text-red-400 font-semibold' : 'text-white/50'">
                  {{ task.due_date ? `〜${formatShort(task.due_date)}` : '' }}
                </span>
                <span v-if="task.progress > 0" class="text-white/50">{{ task.progress }}%</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- リスト -->
    <div v-else class="overflow-x-auto rounded-2xl border border-white/10">
      <table class="w-full text-sm">
        <thead class="bg-white/5 text-white/70 text-xs">
          <tr>
            <th class="w-10 px-3 py-3" />
            <th class="px-4 py-3 text-left font-medium">タイトル</th>
            <th class="px-4 py-3 text-left font-medium">優先度</th>
            <th class="px-4 py-3 text-left font-medium">ステータス</th>
            <th class="px-4 py-3 text-left font-medium">期限</th>
            <th class="px-4 py-3 text-left font-medium">進捗</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-white/10">
          <tr v-if="listTasks.length === 0">
            <td colspan="6" class="px-4 py-10 text-center text-white/50">該当するタスクはありません</td>
          </tr>
          <tr v-for="task in listTasks" :key="task.id" class="cursor-pointer hover:bg-white/5" @click="emit('open', task)">
            <td class="px-3 py-3 text-center" @click.stop>
              <input
                type="checkbox"
                class="accent-primary"
                :checked="task.status === 'done'"
                :disabled="!canEdit"
                @change="emit('move', task, task.status === 'done' ? 'todo' : 'done')"
              />
            </td>
            <td class="px-4 py-3 max-w-[320px] truncate" :class="task.status === 'done' ? 'line-through text-white/50' : ''">
              {{ task.title }}
            </td>
            <td class="px-4 py-3">
              <span class="text-xs px-2 py-0.5 rounded" :class="priorityMeta(task.priority).badge">{{ priorityMeta(task.priority).label }}</span>
            </td>
            <td class="px-4 py-3">
              <span class="text-xs px-3 py-1 rounded-full border" :class="statusMeta(task.status).badge">{{ statusMeta(task.status).label }}</span>
            </td>
            <td class="px-4 py-3 whitespace-nowrap" :class="isOverdue(task) ? 'text-red-400 font-semibold' : 'text-white/80'">
              {{ task.due_date ?? '-' }}
            </td>
            <td class="px-4 py-3 text-white/70">{{ task.progress }}%</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import type { LabTask, TaskStatus } from '../../lib/api'
import { STATUS_OPTIONS, isClosed, parseDate, priorityMeta, statusMeta, todayString } from '../../lib/tasks'

const props = defineProps<{
  tasks: LabTask[]
  allTasks: LabTask[]
  canEdit: boolean
}>()

const emit = defineEmits<{
  open: [task: LabTask]
  move: [task: LabTask, status: TaskStatus]
}>()

type ViewMode = 'board' | 'list'
const viewModes: { value: ViewMode; label: string }[] = [
  { value: 'board', label: 'カンバン' },
  { value: 'list', label: 'リスト' },
]

const VIEW_KEY = 'lab_task_todo_view'
function loadViewMode(): ViewMode {
  try {
    return localStorage.getItem(VIEW_KEY) === 'list' ? 'list' : 'board'
  } catch {
    return 'board'
  }
}
const viewModeState = ref<ViewMode>(loadViewMode())
const viewMode = computed({
  get: () => viewModeState.value,
  set: (value: ViewMode) => {
    viewModeState.value = value
    try {
      localStorage.setItem(VIEW_KEY, value)
    } catch {
      // 保存できなくても表示は切り替える
    }
  },
})

const draggingId = ref<number | null>(null)
const dragOverStatus = ref<TaskStatus | null>(null)

// 優先度の高い順 → 期限の近い順（未設定は最後） → 登録順
function compareTasks(a: LabTask, b: LabTask): number {
  const rank = priorityMeta(b.priority).rank - priorityMeta(a.priority).rank
  if (rank !== 0) return rank
  if (a.due_date !== b.due_date) {
    if (!a.due_date) return 1
    if (!b.due_date) return -1
    return a.due_date < b.due_date ? -1 : 1
  }
  return a.id - b.id
}

const columns = computed(() =>
  STATUS_OPTIONS.map((opt) => ({
    ...opt,
    tasks: props.tasks.filter((t) => t.status === opt.value).sort(compareTasks),
  })),
)

const listTasks = computed(() => [...props.tasks].sort(compareTasks))

const titleById = computed(() => new Map(props.allTasks.map((t) => [t.id, t.title])))

function parentTitle(task: LabTask): string {
  return task.parent != null ? titleById.value.get(task.parent) ?? '' : ''
}

function isOverdue(task: LabTask): boolean {
  return !!task.due_date && !isClosed(task) && task.due_date < todayString()
}

function formatShort(value: string): string {
  const date = parseDate(value)
  return `${date.getMonth() + 1}/${date.getDate()}`
}

function onDragStart(event: DragEvent, task: LabTask) {
  draggingId.value = task.id
  // Firefox はデータを積まないとドラッグが始まらない
  event.dataTransfer?.setData('text/plain', String(task.id))
}

function onDragLeave(event: DragEvent, status: TaskStatus) {
  const related = event.relatedTarget as Node | null
  if (related && (event.currentTarget as HTMLElement).contains(related)) return
  if (dragOverStatus.value === status) dragOverStatus.value = null
}

function onDrop(status: TaskStatus) {
  const task = props.tasks.find((t) => t.id === draggingId.value)
  draggingId.value = null
  dragOverStatus.value = null
  if (task && task.status !== status && props.canEdit) emit('move', task, status)
}
</script>
