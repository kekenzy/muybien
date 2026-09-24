import type { LabTask, TaskPriority, TaskStatus } from './api'

// タスク管理（ToDo / WBS）で共通に使う定義と日付計算。
// 稼働日は土日を除いた日として扱う（祝日マスタは持っていない）。

export const STATUS_OPTIONS: { value: TaskStatus; label: string; dot: string; badge: string; bar: string }[] = [
  { value: 'todo', label: '未着手', dot: 'bg-slate-400', badge: 'border-white/20 text-white/70', bar: 'bg-slate-500/70' },
  { value: 'in_progress', label: '進行中', dot: 'bg-sky-400', badge: 'border-sky-500/40 text-sky-300 bg-sky-500/10', bar: 'bg-sky-500/70' },
  { value: 'review', label: 'レビュー中', dot: 'bg-purple-400', badge: 'border-purple-500/40 text-purple-300 bg-purple-500/10', bar: 'bg-purple-500/70' },
  { value: 'done', label: '完了', dot: 'bg-green-400', badge: 'border-green-500/40 text-green-400 bg-green-500/10', bar: 'bg-green-500/70' },
  { value: 'on_hold', label: '保留', dot: 'bg-orange-400', badge: 'border-orange-500/40 text-orange-300 bg-orange-500/10', bar: 'bg-orange-500/70' },
  { value: 'cancelled', label: '中止', dot: 'bg-red-400', badge: 'border-red-500/40 text-red-300 bg-red-500/10', bar: 'bg-red-500/60' },
]

export const PRIORITY_OPTIONS: { value: TaskPriority; label: string; rank: number; badge: string }[] = [
  { value: 'urgent', label: '緊急', rank: 4, badge: 'bg-red-500/20 text-red-300' },
  { value: 'high', label: '高', rank: 3, badge: 'bg-orange-500/20 text-orange-300' },
  { value: 'medium', label: '中', rank: 2, badge: 'bg-white/10 text-white/70' },
  { value: 'low', label: '低', rank: 1, badge: 'bg-white/5 text-white/50' },
]

export function statusMeta(status: TaskStatus) {
  return STATUS_OPTIONS.find((o) => o.value === status) ?? STATUS_OPTIONS[0]
}

export function priorityMeta(priority: TaskPriority) {
  return PRIORITY_OPTIONS.find((o) => o.value === priority) ?? PRIORITY_OPTIONS[2]
}

export function isClosed(task: LabTask): boolean {
  return task.status === 'done' || task.status === 'cancelled'
}

// ---- 日付（'YYYY-MM-DD' をローカル日付として扱う） ----

export function parseDate(value: string): Date {
  const [y, m, d] = value.split('-').map(Number)
  return new Date(y, m - 1, d)
}

export function toDateString(date: Date): string {
  const m = String(date.getMonth() + 1).padStart(2, '0')
  const d = String(date.getDate()).padStart(2, '0')
  return `${date.getFullYear()}-${m}-${d}`
}

export function todayString(): string {
  return toDateString(new Date())
}

export function addDays(value: string, days: number): string {
  const date = parseDate(value)
  date.setDate(date.getDate() + days)
  return toDateString(date)
}

export function diffDays(from: string, to: string): number {
  return Math.round((parseDate(to).getTime() - parseDate(from).getTime()) / 86400000)
}

export function isWorkingDay(value: string): boolean {
  const day = parseDate(value).getDay()
  return day !== 0 && day !== 6
}

export function nextWorkingDay(value: string): string {
  let date = value
  while (!isWorkingDay(date)) date = addDays(date, 1)
  return date
}

/** 開始日〜終了日（両端含む）の稼働日数 */
export function countWorkingDays(start: string, end: string): number {
  if (end < start) return 0
  let count = 0
  for (let date = start; date <= end; date = addDays(date, 1)) {
    if (isWorkingDay(date)) count++
  }
  return count
}

/** 開始日から稼働日数ぶん進めた終了日（開始日を1日目として数える。端数は切り上げ） */
export function endDateFromDuration(start: string, duration: number): string {
  const days = Math.max(1, Math.ceil(duration))
  let date = nextWorkingDay(start)
  for (let i = 1; i < days; i++) date = nextWorkingDay(addDays(date, 1))
  return date
}

export function formatDuration(value: number): string {
  return Number.isInteger(value) ? String(value) : value.toFixed(2).replace(/0+$/, '')
}

/** 期間列の表示用: duration_days があればそれ、なければ稼働日数 */
export function taskDuration(task: LabTask): number | null {
  if (task.duration_days != null) return Number(task.duration_days)
  if (task.start_date && task.due_date) return countWorkingDays(task.start_date, task.due_date)
  return null
}

// ---- 階層 ----

export interface TaskRow {
  task: LabTask
  level: number
  wbsNo: string
  hasChildren: boolean
}

export function sortSiblings(a: LabTask, b: LabTask): number {
  return a.order - b.order || a.id - b.id
}

/** parent を辿ってツリー順に並べる。親が見つからないタスクはトップレベル扱い。 */
export function buildTaskRows(tasks: LabTask[], collapsed: Set<number> = new Set()): TaskRow[] {
  const ids = new Set(tasks.map((t) => t.id))
  const children = new Map<number | null, LabTask[]>()
  for (const task of tasks) {
    const key = task.parent != null && ids.has(task.parent) ? task.parent : null
    if (!children.has(key)) children.set(key, [])
    children.get(key)!.push(task)
  }
  for (const list of children.values()) list.sort(sortSiblings)

  const rows: TaskRow[] = []
  const walk = (parentId: number | null, level: number, prefix: string) => {
    ;(children.get(parentId) ?? []).forEach((task, i) => {
      const wbsNo = prefix ? `${prefix}.${i + 1}` : String(i + 1)
      const hasChildren = (children.get(task.id)?.length ?? 0) > 0
      rows.push({ task, level, wbsNo, hasChildren })
      if (hasChildren && !collapsed.has(task.id)) walk(task.id, level + 1, wbsNo)
    })
  }
  walk(null, 0, '')
  return rows
}

/** 自分自身と子孫のID（親タスク選択肢から除外するため） */
export function descendantIds(tasks: LabTask[], rootId: number): Set<number> {
  const result = new Set<number>([rootId])
  let added = true
  while (added) {
    added = false
    for (const task of tasks) {
      if (task.parent != null && result.has(task.parent) && !result.has(task.id)) {
        result.add(task.id)
        added = true
      }
    }
  }
  return result
}

// ---- 依存関係の連鎖更新 ----

/** WBSのバー操作で変わる日程 */
export interface ScheduleChange {
  start_date: string
  due_date: string
  duration_days: string
}

export interface DateChange {
  id: number
  start_date: string
  due_date: string
}

/**
 * 先行タスクの終了日が delta 日ずれたとき、後続タスクを同じ日数だけずらす。
 * 開始日が休日なら次の稼働日へ送り、終了日は稼働日数（duration_days）から再計算する。
 */
export function cascadeDependents(tasks: LabTask[], sourceId: number, delta: number): DateChange[] {
  if (delta === 0) return []
  const byId = new Map(tasks.map((t) => [t.id, { ...t }]))
  const changes = new Map<number, DateChange>()
  const visited = new Set<number>([sourceId])

  const visit = (predId: number, shift: number) => {
    for (const task of byId.values()) {
      if (!task.dependencies.includes(predId) || visited.has(task.id)) continue
      if (!task.start_date || !task.due_date) continue
      visited.add(task.id)
      const oldDue = task.due_date
      const start = nextWorkingDay(addDays(task.start_date, shift))
      const duration = task.duration_days != null ? Number(task.duration_days) : countWorkingDays(task.start_date, task.due_date)
      const due = endDateFromDuration(start, duration)
      task.start_date = start
      task.due_date = due
      changes.set(task.id, { id: task.id, start_date: start, due_date: due })
      visit(task.id, diffDays(oldDue, due))
    }
  }
  visit(sourceId, delta)
  return [...changes.values()]
}
