<template>
  <div class="max-w-7xl mx-auto px-6 py-10">
    <div class="mb-6 flex items-center justify-between">
      <div>
        <h2 class="text-xl font-bold">タスク管理</h2>
        <p class="text-sm text-white/60 mt-1">ToDoはカンバンでステータス管理、WBSは階層とガントチャートで日程管理する（同じタスクを別の見せ方で表示）</p>
      </div>
      <button
        v-if="canWrite('tasks')"
        type="button"
        class="shrink-0 text-sm px-4 py-2 rounded-full bg-primary text-black font-medium hover:opacity-90 transition-opacity"
        @click="openCreate()"
      >
        + 新規タスク
      </button>
    </div>

    <div v-if="errorMsg" class="mb-6 bg-red-500/10 border border-red-500/30 text-red-300 rounded-xl p-4 text-sm">
      {{ errorMsg }}
    </div>

    <div class="mb-5 flex gap-2 border-b border-white/10">
      <button
        v-for="item in tabs"
        :key="item.value"
        type="button"
        class="px-4 py-2 text-sm border-b-2 transition-colors"
        :class="tab === item.value ? 'border-primary text-white' : 'border-transparent text-white/50 hover:text-white'"
        @click="tab = item.value"
      >
        {{ item.label }}
      </button>
    </div>

    <div class="mb-4 flex flex-wrap items-center gap-3">
      <input
        v-model="searchQuery"
        type="text"
        placeholder="タイトル・詳細で検索"
        class="flex-1 min-w-[200px] rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm focus:outline-none focus:border-primary/60"
      />
      <select
        v-model="priorityFilter"
        class="rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm focus:outline-none focus:border-primary/60"
      >
        <option value="all">優先度: すべて</option>
        <option v-for="opt in PRIORITY_OPTIONS" :key="opt.value" :value="opt.value">優先度: {{ opt.label }}</option>
      </select>
      <label class="flex items-center gap-2 text-sm text-white/70">
        <input v-model="showClosed" type="checkbox" class="accent-primary" />
        完了・中止も表示
      </label>
    </div>

    <div v-if="loading" class="text-center text-white/60 py-20 text-sm">読み込み中...</div>

    <template v-else>
      <TaskTodoBoard
        v-if="tab === 'todo'"
        :tasks="filteredTasks"
        :all-tasks="tasks"
        :can-edit="canWrite('tasks')"
        @open="openEdit"
        @move="moveStatus"
      />
      <TaskWbsChart
        v-else
        :tasks="filteredTasks"
        :can-edit="canWrite('tasks')"
        @open="openEdit"
        @add-child="openCreate"
        @reschedule="reschedule"
        @reorder="reorder"
        @remove-dependency="removeDependency"
      />
    </template>

    <TaskFormDialog
      v-if="showForm"
      :task="editingTask"
      :tasks="tasks"
      :defaults="formDefaults"
      :readonly="!canWrite('tasks')"
      :saving="saving"
      @close="closeForm"
      @submit="submitForm"
      @delete="removeTask"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import TaskFormDialog from '../../components/lab/TaskFormDialog.vue'
import TaskTodoBoard from '../../components/lab/TaskTodoBoard.vue'
import TaskWbsChart from '../../components/lab/TaskWbsChart.vue'
import {
  createTask,
  deleteTask,
  fetchTasks,
  updateTask,
  type LabTask,
  type LabTaskInput,
  type TaskPriority,
  type TaskStatus,
} from '../../lib/api'
import { canWrite } from '../../lib/permissions'
import { PRIORITY_OPTIONS, cascadeDependents, descendantIds, diffDays, isClosed, type ScheduleChange } from '../../lib/tasks'

type Tab = 'todo' | 'wbs'
const tabs: { value: Tab; label: string }[] = [
  { value: 'todo', label: 'ToDo' },
  { value: 'wbs', label: 'WBS' },
]

const route = useRoute()
const router = useRouter()

// タブは URL の ?tab= に持たせてリロードしても維持する
const tab = computed<Tab>({
  get: () => (route.query.tab === 'wbs' ? 'wbs' : 'todo'),
  set: (value) => router.replace({ query: { ...route.query, tab: value === 'todo' ? undefined : value } }),
})

const tasks = ref<LabTask[]>([])
const loading = ref(true)
const saving = ref(false)
const errorMsg = ref('')

const searchQuery = ref('')
const priorityFilter = ref<'all' | TaskPriority>('all')
const showClosed = ref(true)

const showForm = ref(false)
const editingTask = ref<LabTask | null>(null)
const formDefaults = ref<Partial<LabTaskInput>>({})

const filteredTasks = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  return tasks.value.filter((t) => {
    if (!showClosed.value && isClosed(t)) return false
    if (priorityFilter.value !== 'all' && t.priority !== priorityFilter.value) return false
    if (!query) return true
    return t.title.toLowerCase().includes(query) || t.description.toLowerCase().includes(query)
  })
})

function replaceTask(updated: LabTask) {
  const idx = tasks.value.findIndex((t) => t.id === updated.id)
  if (idx !== -1) tasks.value[idx] = updated
}

async function loadTasks() {
  loading.value = true
  errorMsg.value = ''
  try {
    tasks.value = await fetchTasks()
  } catch {
    errorMsg.value = 'タスクの取得に失敗しました。'
  } finally {
    loading.value = false
  }
}

function nextOrder(parentId: number | null): number {
  const siblings = tasks.value.filter((t) => t.parent === parentId)
  return siblings.reduce((max, t) => Math.max(max, t.order), 0) + 1
}

function openCreate(parent?: LabTask) {
  editingTask.value = null
  formDefaults.value = parent ? { parent: parent.id, start_date: parent.start_date } : {}
  showForm.value = true
}

function openEdit(task: LabTask) {
  editingTask.value = task
  formDefaults.value = {}
  showForm.value = true
}

function closeForm() {
  showForm.value = false
  editingTask.value = null
}

/** 先行タスクの終了日が動いた分だけ後続タスクをずらして保存する */
async function applyCascade(sourceId: number, oldDue: string | null, newDue: string | null) {
  if (!oldDue || !newDue) return
  const changes = cascadeDependents(tasks.value, sourceId, diffDays(oldDue, newDue))
  for (const change of changes) {
    replaceTask(await updateTask(change.id, { start_date: change.start_date, due_date: change.due_date }))
  }
}

async function submitForm(input: LabTaskInput) {
  saving.value = true
  errorMsg.value = ''
  try {
    const current = editingTask.value
    if (current) {
      const payload = { ...input }
      if (payload.parent !== current.parent) payload.order = nextOrder(payload.parent)
      const updated = await updateTask(current.id, payload)
      replaceTask(updated)
      await applyCascade(updated.id, current.due_date, updated.due_date)
    } else {
      const created = await createTask({ ...input, order: nextOrder(input.parent) })
      tasks.value.push(created)
    }
    closeForm()
  } catch {
    errorMsg.value = '保存に失敗しました。'
  } finally {
    saving.value = false
  }
}

async function moveStatus(task: LabTask, status: TaskStatus) {
  const previous = { ...task }
  const patch: Partial<LabTaskInput> = { status }
  if (status === 'done') patch.progress = 100
  replaceTask({ ...task, ...patch }) // 先に画面へ反映
  try {
    replaceTask(await updateTask(task.id, patch))
  } catch {
    replaceTask(previous)
    errorMsg.value = 'ステータスの更新に失敗しました。'
  }
}

async function reschedule(task: LabTask, change: ScheduleChange) {
  errorMsg.value = ''
  try {
    const updated = await updateTask(task.id, change)
    replaceTask(updated)
    await applyCascade(task.id, task.due_date, updated.due_date)
  } catch {
    errorMsg.value = '日程の更新に失敗しました。'
  }
}

async function reorder(task: LabTask, parentId: number | null, orderedIds: number[]) {
  errorMsg.value = ''
  try {
    for (const [i, id] of orderedIds.entries()) {
      const target = tasks.value.find((t) => t.id === id)
      if (!target) continue
      const patch: Partial<LabTaskInput> = {}
      if (target.order !== i + 1) patch.order = i + 1
      if (id === task.id && target.parent !== parentId) patch.parent = parentId
      if (Object.keys(patch).length) replaceTask(await updateTask(id, patch))
    }
  } catch {
    errorMsg.value = '並べ替えに失敗しました。'
    await loadTasks()
  }
}

async function removeDependency(task: LabTask, predecessorId: number) {
  const predecessor = tasks.value.find((t) => t.id === predecessorId)
  if (!confirm(`「${predecessor?.title ?? ''}」→「${task.title}」の依存関係を解除しますか？`)) return
  try {
    replaceTask(await updateTask(task.id, { dependencies: task.dependencies.filter((id) => id !== predecessorId) }))
  } catch {
    errorMsg.value = '依存関係の解除に失敗しました。'
  }
}

async function removeTask(task: LabTask) {
  const removed = descendantIds(tasks.value, task.id)
  const note = removed.size > 1 ? `\n子タスク ${removed.size - 1} 件も一緒に削除されます。` : ''
  if (!confirm(`「${task.title}」を削除しますか？${note}`)) return
  try {
    await deleteTask(task.id)
    tasks.value = tasks.value
      .filter((t) => !removed.has(t.id))
      .map((t) => (t.dependencies.some((id) => removed.has(id)) ? { ...t, dependencies: t.dependencies.filter((id) => !removed.has(id)) } : t))
    closeForm()
  } catch {
    errorMsg.value = '削除に失敗しました。'
  }
}

onMounted(loadTasks)
</script>
