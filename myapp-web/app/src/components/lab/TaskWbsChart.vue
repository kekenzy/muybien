<template>
  <div>
    <div class="mb-3 flex flex-wrap items-center gap-3 text-xs text-white/60">
      <button type="button" class="hover:text-white transition-colors" @click="expandAll">すべて展開</button>
      <button type="button" class="hover:text-white transition-colors" @click="collapseAll">すべて折りたたむ</button>
      <button type="button" class="hover:text-white transition-colors" @click="scrollToToday">今日へ移動</button>
      <span class="ml-auto text-white/40">
        バーをドラッグで日程変更・両端で期間変更 / 行の ⋮⋮ をドラッグで並べ替え / 矢印クリックで依存解除
      </span>
    </div>

    <div v-if="rows.length === 0" class="rounded-2xl border border-white/10 py-20 text-center text-sm text-white/60">
      該当するタスクはありません
    </div>

    <div v-else ref="scroller" class="relative max-h-[72vh] overflow-auto rounded-2xl border border-white/10 select-none">
      <div :style="{ width: `${LEFT_WIDTH + timelineWidth}px` }">
        <!-- ヘッダー（上に固定） -->
        <div class="sticky top-0 z-20 flex bg-[#0c1220] border-b border-white/10" :style="{ height: `${HEADER_HEIGHT}px` }">
          <div
            class="sticky left-0 z-30 flex items-end bg-[#0c1220] border-r border-white/10 text-[11px] text-white/60"
            :style="{ width: `${LEFT_WIDTH}px` }"
          >
            <div v-for="col in COLUMNS" :key="col.key" class="px-2 pb-2 truncate" :class="col.align" :style="{ width: `${col.width}px` }">
              {{ col.label }}
            </div>
          </div>
          <div class="relative" :style="{ width: `${timelineWidth}px` }">
            <div
              v-for="month in months"
              :key="month.key"
              class="absolute top-0 h-5 border-l border-white/15 px-1.5 text-[11px] leading-5 text-white/70 whitespace-nowrap"
              :style="{ left: `${month.offset * DAY_WIDTH}px`, width: `${month.days * DAY_WIDTH}px` }"
            >
              {{ month.label }}
            </div>
            <div
              v-for="day in days"
              :key="day.date"
              class="absolute bottom-0 h-6 text-center text-[10px] leading-6"
              :class="day.isToday ? 'bg-primary text-white font-semibold rounded-t' : day.isWeekend ? 'text-white/30' : 'text-white/50'"
              :style="{ left: `${day.offset * DAY_WIDTH}px`, width: `${DAY_WIDTH}px` }"
            >
              {{ day.label }}
            </div>
          </div>
        </div>

        <!-- 本体 -->
        <div class="relative" :style="{ height: `${rows.length * ROW_HEIGHT}px` }">
          <!-- 背景（土日・今日・月初） -->
          <div class="absolute top-0 bottom-0" :style="{ left: `${LEFT_WIDTH}px`, width: `${timelineWidth}px` }">
            <div
              v-for="day in shadedDays"
              :key="day.date"
              class="absolute top-0 bottom-0"
              :class="[day.isToday ? 'bg-primary/15' : day.isWeekend ? 'bg-white/[0.035]' : '', day.isMonthStart ? 'border-l border-white/15' : '']"
              :style="{ left: `${day.offset * DAY_WIDTH}px`, width: `${DAY_WIDTH}px` }"
            />
          </div>

          <!-- 依存関係の矢印 -->
          <svg
            class="absolute top-0 z-[5] pointer-events-none overflow-visible"
            :style="{ left: `${LEFT_WIDTH}px` }"
            :width="timelineWidth"
            :height="rows.length * ROW_HEIGHT"
          >
            <defs>
              <marker id="wbs-arrow" viewBox="0 0 8 8" refX="7" refY="4" markerWidth="7" markerHeight="7" orient="auto">
                <path d="M0,0 L8,4 L0,8 z" class="fill-white/60" />
              </marker>
            </defs>
            <path
              v-for="link in links"
              :key="link.key"
              :d="link.path"
              fill="none"
              stroke-width="1.5"
              marker-end="url(#wbs-arrow)"
              class="stroke-white/40 hover:stroke-red-400"
              :class="canEdit ? 'pointer-events-auto cursor-pointer' : ''"
              @click="canEdit && emit('remove-dependency', link.task, link.predecessorId)"
            />
          </svg>

          <div
            v-for="(row, index) in rows"
            :key="row.task.id"
            class="absolute left-0 flex w-full border-b border-white/5"
            :class="dropTarget?.id === row.task.id ? (dropTarget.position === 'before' ? 'border-t-2 border-t-primary' : 'border-b-2 border-b-primary') : ''"
            :style="{ top: `${index * ROW_HEIGHT}px`, height: `${ROW_HEIGHT}px` }"
            @dragover.prevent="onRowDragOver($event, row)"
            @drop.prevent="onRowDrop"
          >
            <!-- 左側の列（横スクロールしても固定） -->
            <div
              class="group sticky left-0 z-10 flex items-center bg-[#080c14] hover:bg-[#101827] border-r border-white/10 text-xs cursor-pointer"
              :class="draggingRowId === row.task.id ? 'opacity-40' : ''"
              :style="{ width: `${LEFT_WIDTH}px` }"
              @click="emit('open', row.task)"
            >
              <div class="flex items-center gap-1 px-2 text-white/50 tabular-nums" :style="{ width: `${COLUMNS[0].width}px` }">
                <span
                  v-if="canEdit"
                  draggable="true"
                  class="cursor-grab text-white/20 hover:text-white/70"
                  title="ドラッグで並べ替え"
                  @click.stop
                  @dragstart="onRowDragStart($event, row)"
                  @dragend="onRowDragEnd"
                >⋮⋮</span>
                {{ row.wbsNo }}
              </div>
              <div class="flex items-center min-w-0 pr-2" :style="{ width: `${COLUMNS[1].width}px`, paddingLeft: `${row.level * 16}px` }">
                <button
                  v-if="row.hasChildren"
                  type="button"
                  class="w-4 shrink-0 text-white/50 hover:text-white"
                  @click.stop="toggle(row.task.id)"
                >
                  {{ collapsed.has(row.task.id) ? '▸' : '▾' }}
                </button>
                <span v-else class="w-4 shrink-0" />
                <span
                  class="truncate"
                  :class="[row.hasChildren ? 'font-semibold' : '', row.task.status === 'done' ? 'line-through text-white/50' : '']"
                  :title="row.task.title"
                >
                  {{ row.task.title }}
                </span>
                <button
                  v-if="canEdit"
                  type="button"
                  class="ml-auto shrink-0 pl-1 text-white/40 hover:text-white opacity-0 group-hover:opacity-100 transition-opacity"
                  title="子タスクを追加"
                  @click.stop="emit('add-child', row.task)"
                >
                  ＋
                </button>
              </div>
              <div class="px-2 text-center" :style="{ width: `${COLUMNS[2].width}px` }">
                <span class="text-[10px] px-1.5 py-0.5 rounded" :class="priorityMeta(row.task.priority).badge">
                  {{ priorityMeta(row.task.priority).label }}
                </span>
              </div>
              <div class="px-2 text-white/70 tabular-nums" :style="{ width: `${COLUMNS[3].width}px` }">{{ shortDate(row.task.start_date) }}</div>
              <div
                class="px-2 tabular-nums"
                :class="isOverdue(row.task) ? 'text-red-400 font-semibold' : 'text-white/70'"
                :style="{ width: `${COLUMNS[4].width}px` }"
              >
                {{ shortDate(row.task.due_date) }}
              </div>
              <div class="px-2 text-right text-white/70 tabular-nums" :style="{ width: `${COLUMNS[5].width}px` }">
                {{ durationLabel(row.task) }}
              </div>
              <div class="px-2" :style="{ width: `${COLUMNS[6].width}px` }">
                <span class="inline-flex items-center gap-1 text-[11px] text-white/70">
                  <span class="h-1.5 w-1.5 rounded-full" :class="statusMeta(row.task.status).dot" />
                  {{ statusMeta(row.task.status).label }}
                </span>
              </div>
              <div class="px-2 text-right text-white/70 tabular-nums" :style="{ width: `${COLUMNS[7].width}px` }">{{ row.task.progress }}%</div>
            </div>

            <!-- タイムライン -->
            <div class="relative" :style="{ width: `${timelineWidth}px` }">
              <template v-if="barOf(row)">
                <div
                  class="absolute top-1.5 bottom-1.5 rounded-md overflow-hidden text-[10px] leading-5 text-white whitespace-nowrap"
                  :class="[
                    row.hasChildren ? 'bg-white/25' : statusMeta(row.task.status).bar,
                    canEdit && barOf(row)!.editable ? 'cursor-grab active:cursor-grabbing' : 'cursor-pointer',
                    dragging?.id === row.task.id ? 'ring-2 ring-primary' : '',
                  ]"
                  :style="barStyle(barOf(row)!)"
                  :title="`${row.task.title}（${barOf(row)!.start} 〜 ${barOf(row)!.end}）`"
                  @pointerdown="onBarPointerDown($event, row, 'move')"
                >
                  <div class="absolute inset-y-0 left-0 bg-white/25" :style="{ width: `${row.task.progress}%` }" />
                  <span class="relative px-1.5">{{ row.task.title }}</span>
                  <template v-if="canEdit && barOf(row)!.editable">
                    <div
                      class="absolute inset-y-0 left-0 w-1.5 cursor-ew-resize hover:bg-white/40"
                      @pointerdown.stop="onBarPointerDown($event, row, 'start')"
                    />
                    <div
                      class="absolute inset-y-0 right-0 w-1.5 cursor-ew-resize hover:bg-white/40"
                      @pointerdown.stop="onBarPointerDown($event, row, 'end')"
                    />
                  </template>
                </div>
              </template>
              <span v-else class="absolute top-0 h-full px-3 text-[10px] leading-8 text-white/25" :style="{ left: `${todayOffset * DAY_WIDTH}px` }">
                日付未設定
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref } from 'vue'
import type { LabTask } from '../../lib/api'
import {
  addDays,
  buildTaskRows,
  countWorkingDays,
  descendantIds,
  diffDays,
  endDateFromDuration,
  formatDuration,
  isClosed,
  isWorkingDay,
  nextWorkingDay,
  parseDate,
  priorityMeta,
  sortSiblings,
  statusMeta,
  taskDuration,
  toDateString,
  todayString,
  type ScheduleChange,
  type TaskRow,
} from '../../lib/tasks'

const props = defineProps<{
  tasks: LabTask[]
  canEdit: boolean
}>()

const emit = defineEmits<{
  open: [task: LabTask]
  'add-child': [task: LabTask]
  reschedule: [task: LabTask, change: ScheduleChange]
  reorder: [task: LabTask, parentId: number | null, orderedIds: number[]]
  'remove-dependency': [task: LabTask, predecessorId: number]
}>()

const DAY_WIDTH = 28
const ROW_HEIGHT = 32
const HEADER_HEIGHT = 44
const COLUMNS = [
  { key: 'no', label: '#', width: 64, align: '' },
  { key: 'title', label: 'タスク名', width: 250, align: '' },
  { key: 'priority', label: '優先度', width: 52, align: 'text-center' },
  { key: 'start', label: '開始日', width: 56, align: '' },
  { key: 'end', label: '終了日', width: 56, align: '' },
  { key: 'duration', label: '期間', width: 44, align: 'text-right' },
  { key: 'status', label: 'ステータス', width: 78, align: '' },
  { key: 'progress', label: '進捗', width: 48, align: 'text-right' },
]
const LEFT_WIDTH = COLUMNS.reduce((sum, col) => sum + col.width, 0)

const scroller = ref<HTMLElement | null>(null)

// ---- 折りたたみ（ブラウザに保存） ----
const COLLAPSE_KEY = 'lab_task_wbs_collapsed'
function loadCollapsed(): Set<number> {
  try {
    return new Set(JSON.parse(localStorage.getItem(COLLAPSE_KEY) ?? '[]') as number[])
  } catch {
    return new Set()
  }
}
const collapsed = ref<Set<number>>(loadCollapsed())
function saveCollapsed() {
  try {
    localStorage.setItem(COLLAPSE_KEY, JSON.stringify([...collapsed.value]))
  } catch {
    // 保存できなくても表示は切り替える
  }
}
function toggle(id: number) {
  const next = new Set(collapsed.value)
  if (next.has(id)) next.delete(id)
  else next.add(id)
  collapsed.value = next
  saveCollapsed()
}
function expandAll() {
  collapsed.value = new Set()
  saveCollapsed()
}
function collapseAll() {
  collapsed.value = new Set(props.tasks.filter((t) => props.tasks.some((c) => c.parent === t.id)).map((t) => t.id))
  saveCollapsed()
}

const rows = computed(() => buildTaskRows(props.tasks, collapsed.value))

// ---- タイムラインの範囲（今日の1ヶ月前〜4ヶ月後を基本に、タスクの日付を含むよう月単位で広げる） ----
const today = todayString()

const range = computed(() => {
  const dates = props.tasks.flatMap((t) => [t.start_date, t.due_date]).filter((d): d is string => !!d)
  let min = addDays(today, -30)
  let max = addDays(today, 120)
  for (const d of dates) {
    if (d < min) min = d
    if (d > max) max = d
  }
  const start = parseDate(min)
  start.setDate(1)
  const end = parseDate(max)
  end.setMonth(end.getMonth() + 1, 0)
  return { start: toDateString(start), end: toDateString(end) }
})

const totalDays = computed(() => diffDays(range.value.start, range.value.end) + 1)
const timelineWidth = computed(() => totalDays.value * DAY_WIDTH)
const todayOffset = computed(() => diffDays(range.value.start, today))

const days = computed(() =>
  Array.from({ length: totalDays.value }, (_, offset) => {
    const date = addDays(range.value.start, offset)
    const d = parseDate(date)
    return {
      date,
      offset,
      label: String(d.getDate()),
      isToday: date === today,
      isWeekend: !isWorkingDay(date),
      isMonthStart: d.getDate() === 1,
    }
  }),
)
const shadedDays = computed(() => days.value.filter((d) => d.isToday || d.isWeekend || d.isMonthStart))

const months = computed(() => {
  const result: { key: string; label: string; offset: number; days: number }[] = []
  for (const day of days.value) {
    if (day.offset === 0 || day.isMonthStart) {
      const d = parseDate(day.date)
      result.push({ key: day.date, label: `${d.getFullYear()}年${d.getMonth() + 1}月`, offset: day.offset, days: 0 })
    }
    result[result.length - 1].days++
  }
  return result
})

// ---- バー ----
interface Bar {
  start: string
  end: string
  editable: boolean
}

const dragging = ref<{ id: number; start: string; end: string } | null>(null)

/** 子を持つ行で日付未設定なら子孫の期間をまとめて表示する */
const summaryRanges = computed(() => {
  const result = new Map<number, { start: string; end: string }>()
  for (const task of props.tasks) {
    if (task.start_date || task.due_date) continue
    const ids = descendantIds(props.tasks, task.id)
    ids.delete(task.id)
    const dates = props.tasks.filter((t) => ids.has(t.id)).flatMap((t) => [t.start_date, t.due_date]).filter((d): d is string => !!d)
    if (dates.length) result.set(task.id, { start: dates.reduce((a, b) => (a < b ? a : b)), end: dates.reduce((a, b) => (a > b ? a : b)) })
  }
  return result
})

function barOf(row: TaskRow): Bar | null {
  const task = row.task
  if (dragging.value?.id === task.id) return { start: dragging.value.start, end: dragging.value.end, editable: true }
  if (task.start_date || task.due_date) {
    const start = task.start_date ?? task.due_date!
    const end = task.due_date ?? task.start_date!
    return { start, end, editable: !!task.start_date && !!task.due_date }
  }
  const summary = summaryRanges.value.get(task.id)
  return summary ? { ...summary, editable: false } : null
}

function barStyle(bar: Bar) {
  const left = diffDays(range.value.start, bar.start) * DAY_WIDTH
  const width = Math.max(1, diffDays(bar.start, bar.end) + 1) * DAY_WIDTH
  return { left: `${left + 1}px`, width: `${width - 2}px` }
}

// ---- バーのドラッグ（移動・期間変更） ----
type DragMode = 'move' | 'start' | 'end'
let dragState: { row: TaskRow; mode: DragMode; startX: number; start: string; end: string; moved: boolean } | null = null

function onBarPointerDown(event: PointerEvent, row: TaskRow, mode: DragMode) {
  if (event.button !== 0) return
  const task = row.task
  if (!props.canEdit || !task.start_date || !task.due_date) {
    if (mode === 'move') dragState = { row, mode, startX: event.clientX, start: '', end: '', moved: false }
    window.addEventListener('pointerup', onPointerUp, { once: true })
    return
  }
  event.preventDefault()
  dragState = { row, mode, startX: event.clientX, start: task.start_date, end: task.due_date, moved: false }
  window.addEventListener('pointermove', onPointerMove)
  window.addEventListener('pointerup', onPointerUp, { once: true })
}

function draggedDates(delta: number): { start: string; end: string } {
  const state = dragState!
  if (state.mode === 'move') {
    const duration = taskDuration(state.row.task) ?? countWorkingDays(state.start, state.end)
    const start = nextWorkingDay(addDays(state.start, delta))
    return { start, end: endDateFromDuration(start, duration) }
  }
  if (state.mode === 'start') {
    const start = addDays(state.start, delta)
    return { start: start > state.end ? state.end : start, end: state.end }
  }
  const end = addDays(state.end, delta)
  return { start: state.start, end: end < state.start ? state.start : end }
}

function onPointerMove(event: PointerEvent) {
  if (!dragState) return
  const delta = Math.round((event.clientX - dragState.startX) / DAY_WIDTH)
  if (delta !== 0) dragState.moved = true
  if (!dragState.moved) return
  dragging.value = { id: dragState.row.task.id, ...draggedDates(delta) }
}

function onPointerUp(event: PointerEvent) {
  window.removeEventListener('pointermove', onPointerMove)
  const state = dragState
  dragState = null
  const preview = dragging.value
  dragging.value = null
  if (!state) return
  if (!state.moved) {
    // ドラッグしていなければクリック扱いで編集を開く
    if (Math.abs(event.clientX - state.startX) < 4) emit('open', state.row.task)
    return
  }
  if (!preview || (preview.start === state.start && preview.end === state.end)) return
  const duration =
    state.mode === 'move' && state.row.task.duration_days != null
      ? Number(state.row.task.duration_days)
      : countWorkingDays(preview.start, preview.end)
  emit('reschedule', state.row.task, {
    start_date: preview.start,
    due_date: preview.end,
    duration_days: duration.toFixed(2),
  })
}

onBeforeUnmount(() => {
  window.removeEventListener('pointermove', onPointerMove)
  window.removeEventListener('pointerup', onPointerUp)
})

// ---- 依存関係の矢印 ----
const links = computed(() => {
  const indexById = new Map(rows.value.map((row, i) => [row.task.id, i]))
  const result: { key: string; path: string; task: LabTask; predecessorId: number }[] = []
  rows.value.forEach((row, index) => {
    const bar = barOf(row)
    if (!bar) return
    for (const predId of row.task.dependencies) {
      const predIndex = indexById.get(predId)
      if (predIndex === undefined) continue
      const predBar = barOf(rows.value[predIndex])
      if (!predBar) continue
      const x1 = (diffDays(range.value.start, predBar.end) + 1) * DAY_WIDTH - 1
      const y1 = predIndex * ROW_HEIGHT + ROW_HEIGHT / 2
      const x2 = diffDays(range.value.start, bar.start) * DAY_WIDTH + 1
      const y2 = index * ROW_HEIGHT + ROW_HEIGHT / 2
      // 後続の開始が先行の終了より右なら L 字、重なっていれば一度折り返す
      const path =
        x2 - 8 >= x1 + 8
          ? `M${x1},${y1} H${x1 + 8} V${y2} H${x2}`
          : `M${x1},${y1} H${x1 + 8} V${(y1 + y2) / 2} H${x2 - 10} V${y2} H${x2}`
      result.push({ key: `${predId}-${row.task.id}`, path, task: row.task, predecessorId: predId })
    }
  })
  return result
})

// ---- 行の並べ替え（上半分に落とすと前、下半分なら後ろ。落とした行と同じ親に入る） ----
const draggingRowId = ref<number | null>(null)
const dropTarget = ref<{ id: number; position: 'before' | 'after' } | null>(null)

function onRowDragStart(event: DragEvent, row: TaskRow) {
  draggingRowId.value = row.task.id
  event.dataTransfer?.setData('text/plain', String(row.task.id))
  if (event.dataTransfer) event.dataTransfer.effectAllowed = 'move'
}

function onRowDragEnd() {
  draggingRowId.value = null
  dropTarget.value = null
}

function onRowDragOver(event: DragEvent, row: TaskRow) {
  if (draggingRowId.value == null) return
  if (descendantIds(props.tasks, draggingRowId.value).has(row.task.id)) {
    dropTarget.value = null
    return
  }
  const rect = (event.currentTarget as HTMLElement).getBoundingClientRect()
  dropTarget.value = { id: row.task.id, position: event.clientY - rect.top < rect.height / 2 ? 'before' : 'after' }
}

function onRowDrop() {
  const draggedId = draggingRowId.value
  const target = dropTarget.value
  onRowDragEnd()
  if (draggedId == null || !target || target.id === draggedId) return
  const dragged = props.tasks.find((t) => t.id === draggedId)
  const targetTask = props.tasks.find((t) => t.id === target.id)
  if (!dragged || !targetTask) return

  const parentId = targetTask.parent
  const siblings = props.tasks.filter((t) => t.parent === parentId && t.id !== draggedId).sort(sortSiblings)
  const index = siblings.findIndex((t) => t.id === targetTask.id) + (target.position === 'after' ? 1 : 0)
  const orderedIds = siblings.map((t) => t.id)
  orderedIds.splice(index, 0, draggedId)
  emit('reorder', dragged, parentId, orderedIds)
}

// ---- 表示用 ----
function shortDate(value: string | null): string {
  if (!value) return '-'
  const d = parseDate(value)
  return `${d.getMonth() + 1}/${d.getDate()}`
}

function durationLabel(task: LabTask): string {
  const value = taskDuration(task)
  return value != null ? `${formatDuration(value)}日` : '-'
}

function isOverdue(task: LabTask): boolean {
  return !!task.due_date && !isClosed(task) && task.due_date < today
}

function scrollToToday() {
  const el = scroller.value
  if (!el) return
  el.scrollLeft = Math.max(0, todayOffset.value * DAY_WIDTH - (el.clientWidth - LEFT_WIDTH) / 2)
}

onMounted(() => nextTick(scrollToToday))

defineExpose({ scrollToToday })
</script>
