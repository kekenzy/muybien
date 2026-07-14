<template>
  <div class="max-w-5xl mx-auto px-6 py-10">
    <div class="mb-6 flex items-center justify-between">
      <div>
        <h2 class="text-xl font-bold">タスク一覧</h2>
        <p class="text-sm text-white/60 mt-1">やることを登録・管理する</p>
      </div>
      <button
        v-if="canWrite('tasks')"
        type="button"
        class="text-sm px-4 py-2 rounded-full bg-primary text-black font-medium hover:opacity-90 transition-opacity"
        @click="openCreateForm"
      >
        + 新規タスク
      </button>
    </div>

    <div v-if="errorMsg" class="mb-6 bg-red-500/10 border border-red-500/30 text-red-300 rounded-xl p-4 text-sm">
      {{ errorMsg }}
    </div>

    <div class="mb-4 flex flex-wrap items-center gap-3">
      <input
        v-model="searchQuery"
        type="text"
        placeholder="タイトル・詳細で検索"
        class="flex-1 min-w-[200px] rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm focus:outline-none focus:border-primary/60"
      />
      <select
        v-model="statusFilter"
        class="rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm focus:outline-none focus:border-primary/60"
      >
        <option value="all">すべて</option>
        <option v-for="opt in statusOptions" :key="opt.value" :value="opt.value">{{ opt.label }}</option>
      </select>
    </div>

    <div v-if="loading" class="text-center text-white/60 py-20 text-sm">読み込み中...</div>

    <div v-else-if="sortedTasks.length === 0" class="text-center text-white/60 py-20 text-sm">
      該当するタスクはありません
    </div>

    <template v-else>
      <div class="overflow-x-auto rounded-2xl border border-white/10">
        <table class="w-full text-sm">
          <thead class="bg-white/5 text-white/70 text-xs">
            <tr>
              <th class="px-4 py-3 text-left font-medium cursor-pointer select-none" @click="sortBy('title')">
                タイトル{{ sortIndicator('title') }}
              </th>
              <th class="px-4 py-3 text-left font-medium cursor-pointer select-none" @click="sortBy('status')">
                ステータス{{ sortIndicator('status') }}
              </th>
              <th class="px-4 py-3 text-left font-medium cursor-pointer select-none" @click="sortBy('due_date')">
                期限{{ sortIndicator('due_date') }}
              </th>
              <th class="px-4 py-3 text-left font-medium cursor-pointer select-none" @click="sortBy('updated_at')">
                更新日時{{ sortIndicator('updated_at') }}
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-white/10">
            <tr
              v-for="task in pagedTasks"
              :key="task.id"
              class="cursor-pointer hover:bg-white/5"
              @click="openEditForm(task)"
            >
              <td class="px-4 py-3 max-w-[240px] truncate">{{ task.title }}</td>
              <td class="px-4 py-3">
                <span class="text-xs px-3 py-1 rounded-full border" :class="statusStyle(task.status)">
                  {{ statusLabel(task.status) }}
                </span>
              </td>
              <td class="px-4 py-3 whitespace-nowrap text-white/80">{{ task.due_date ?? '-' }}</td>
              <td class="px-4 py-3 whitespace-nowrap text-white/80">{{ formatDate(task.updated_at) }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="mt-4 flex items-center justify-between text-xs text-white/60">
        <span>{{ rangeLabel }}</span>
        <div class="flex items-center gap-3">
          <button type="button" class="disabled:opacity-30 hover:text-white transition-colors" :disabled="page <= 1" @click="page--">
            ◀ 前へ
          </button>
          <span>{{ page }} / {{ totalPages }}</span>
          <button
            type="button"
            class="disabled:opacity-30 hover:text-white transition-colors"
            :disabled="page >= totalPages"
            @click="page++"
          >
            次へ ▶
          </button>
        </div>
      </div>
    </template>

    <div
      v-if="showForm"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4"
      @click.self="closeForm"
    >
      <div class="w-full max-w-2xl max-h-[90vh] overflow-y-auto rounded-2xl border border-white/10 bg-[#0c1220] p-8 space-y-5">
        <div class="flex items-center justify-between">
          <h3 class="font-semibold text-base">{{ editingTask ? 'タスクを編集' : 'タスクを新規作成' }}</h3>
          <button type="button" class="text-white/60 hover:text-white transition-colors" @click="closeForm">✕</button>
        </div>

        <div>
          <label class="block text-xs text-white/60 mb-1">タイトル</label>
          <input
            v-model="form.title"
            type="text"
            :disabled="!canWrite('tasks')"
            class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2.5 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50"
          />
        </div>

        <div>
          <label class="block text-xs text-white/60 mb-1">詳細</label>
          <textarea
            v-model="form.description"
            rows="7"
            :disabled="!canWrite('tasks')"
            class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2.5 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50"
          />
        </div>

        <div class="flex gap-4">
          <div>
            <label class="block text-xs text-white/60 mb-1">ステータス</label>
            <select
              v-model="form.status"
              :disabled="!canWrite('tasks')"
              class="rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50"
            >
              <option v-for="opt in statusOptions" :key="opt.value" :value="opt.value">{{ opt.label }}</option>
            </select>
          </div>
          <div>
            <label class="block text-xs text-white/60 mb-1">期限</label>
            <input
              v-model="form.due_date"
              type="date"
              :disabled="!canWrite('tasks')"
              class="rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50"
            />
          </div>
        </div>

        <div class="flex items-center justify-between pt-2">
          <button
            v-if="editingTask && canWrite('tasks')"
            type="button"
            class="text-xs text-red-400/70 hover:text-red-400 transition-colors"
            @click="removeTask(editingTask)"
          >
            削除
          </button>
          <span v-else />
          <div class="flex gap-3">
            <button
              type="button"
              class="text-sm px-4 py-2 rounded-full border border-white/20 text-white/80 hover:text-white transition-colors"
              @click="closeForm"
            >
              {{ canWrite('tasks') ? 'キャンセル' : '閉じる' }}
            </button>
            <button
              v-if="canWrite('tasks')"
              type="button"
              class="text-sm px-4 py-2 rounded-full bg-primary text-black font-medium hover:opacity-90 transition-opacity disabled:opacity-50"
              :disabled="!form.title || saving"
              @click="submitForm"
            >
              {{ editingTask ? '更新する' : '作成する' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import {
  createTask,
  deleteTask,
  fetchTasks,
  updateTask,
  type LabTask,
  type LabTaskInput,
  type TaskStatus,
} from '../../lib/api'
import { canWrite } from '../../lib/permissions'

type SortKey = 'title' | 'status' | 'due_date' | 'updated_at'
type StatusFilter = 'all' | TaskStatus

const tasks = ref<LabTask[]>([])
const loading = ref(true)
const saving = ref(false)
const errorMsg = ref('')
const showForm = ref(false)
const editingTask = ref<LabTask | null>(null)

const searchQuery = ref('')
const statusFilter = ref<StatusFilter>('all')
const sortKey = ref<SortKey>('due_date')
const sortAsc = ref(true)
const page = ref(1)
const pageSize = 20

const statusOptions: { value: TaskStatus; label: string }[] = [
  { value: 'todo', label: '未着手' },
  { value: 'in_progress', label: '進行中' },
  { value: 'done', label: '完了' },
]

const form = reactive<LabTaskInput>({
  title: '',
  description: '',
  status: 'todo',
  due_date: null,
})

function statusLabel(status: TaskStatus): string {
  return statusOptions.find((o) => o.value === status)?.label ?? status
}

function statusStyle(status: TaskStatus): string {
  if (status === 'done') return 'border-green-500/40 text-green-400 bg-green-500/10'
  if (status === 'in_progress') return 'border-yellow-500/40 text-yellow-400 bg-yellow-500/10'
  return 'border-white/20 text-white/70'
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleString('ja-JP', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  })
}

const filteredTasks = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  return tasks.value.filter((t) => {
    if (statusFilter.value !== 'all' && t.status !== statusFilter.value) return false
    if (!query) return true
    return t.title.toLowerCase().includes(query) || t.description.toLowerCase().includes(query)
  })
})

const sortedTasks = computed(() => {
  const list = [...filteredTasks.value]
  list.sort((a, b) => {
    const av = a[sortKey.value] ?? ''
    const bv = b[sortKey.value] ?? ''
    if (av < bv) return sortAsc.value ? -1 : 1
    if (av > bv) return sortAsc.value ? 1 : -1
    return 0
  })
  return list
})

const totalPages = computed(() => Math.max(1, Math.ceil(sortedTasks.value.length / pageSize)))

const pagedTasks = computed(() => {
  const start = (page.value - 1) * pageSize
  return sortedTasks.value.slice(start, start + pageSize)
})

const rangeLabel = computed(() => {
  const total = sortedTasks.value.length
  if (total === 0) return '0件'
  const start = (page.value - 1) * pageSize + 1
  const end = Math.min(total, page.value * pageSize)
  return `${start}〜${end}件 / 全${total}件`
})

function sortBy(key: SortKey) {
  if (sortKey.value === key) {
    sortAsc.value = !sortAsc.value
  } else {
    sortKey.value = key
    sortAsc.value = true
  }
}

function sortIndicator(key: SortKey): string {
  if (sortKey.value !== key) return ''
  return sortAsc.value ? ' ▲' : ' ▼'
}

watch([searchQuery, statusFilter], () => {
  page.value = 1
})

watch(totalPages, (pages) => {
  if (page.value > pages) page.value = pages
})

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

function resetForm() {
  form.title = ''
  form.description = ''
  form.status = 'todo'
  form.due_date = null
}

function openCreateForm() {
  editingTask.value = null
  resetForm()
  showForm.value = true
}

function openEditForm(task: LabTask) {
  editingTask.value = task
  form.title = task.title
  form.description = task.description
  form.status = task.status
  form.due_date = task.due_date
  showForm.value = true
}

function closeForm() {
  showForm.value = false
  editingTask.value = null
}

async function submitForm() {
  saving.value = true
  errorMsg.value = ''
  try {
    if (editingTask.value) {
      const updated = await updateTask(editingTask.value.id, { ...form })
      const idx = tasks.value.findIndex((t) => t.id === updated.id)
      if (idx !== -1) tasks.value[idx] = updated
    } else {
      const created = await createTask({ ...form })
      tasks.value.unshift(created)
    }
    closeForm()
  } catch {
    errorMsg.value = '保存に失敗しました。'
  } finally {
    saving.value = false
  }
}

async function removeTask(task: LabTask) {
  if (!confirm(`「${task.title}」を削除しますか？`)) return
  try {
    await deleteTask(task.id)
    tasks.value = tasks.value.filter((t) => t.id !== task.id)
    closeForm()
  } catch {
    errorMsg.value = '削除に失敗しました。'
  }
}

onMounted(loadTasks)
</script>
