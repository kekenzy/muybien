<template>
  <div class="max-w-4xl mx-auto px-6 py-10">
    <div class="mb-8 flex items-center justify-between">
      <div>
        <h2 class="text-xl font-bold">日記</h2>
        <p class="text-sm text-white/60 mt-1">カレンダーから日付を選んで記録する</p>
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
        <span v-if="day.diary" class="w-full truncate text-[10px] text-primary">
          📔 {{ day.diary.title || day.diary.content }}
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
            rows="12"
            :disabled="!canWrite('diary')"
            class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2.5 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50"
          />
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
            :disabled="!form.content || saving"
            @click="saveDiary"
          >
            {{ selectedDiary ? '更新する' : '保存する' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import {
  createDiary,
  deleteDiary,
  fetchDiaries,
  fetchTasks,
  updateDiary,
  type DiaryEntry,
  type LabTask,
} from '../../lib/api'
import { canWrite } from '../../lib/permissions'

const weekdays = ['日', '月', '火', '水', '木', '金', '土']

const today = new Date()
const year = ref(today.getFullYear())
const month = ref(today.getMonth() + 1)

const diaries = ref<DiaryEntry[]>([])
const tasks = ref<LabTask[]>([])
const loading = ref(true)
const saving = ref(false)
const errorMsg = ref('')
const selectedDate = ref<string>(toIso(today))
const showDialog = ref(false)

const form = reactive({ title: '', content: '' })

interface CalendarDay {
  date: Date
  iso: string
  inMonth: boolean
  diary: DiaryEntry | undefined
  tasks: LabTask[]
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

function applySelectedToForm() {
  form.title = selectedDiary.value?.title ?? ''
  form.content = selectedDiary.value?.content ?? ''
}

function selectDay(iso: string) {
  selectedDate.value = iso
  applySelectedToForm()
  showDialog.value = true
}

function closeDialog() {
  showDialog.value = false
}

async function loadCalendarData() {
  loading.value = true
  errorMsg.value = ''
  try {
    const [diaryData, taskData] = await Promise.all([fetchDiaries(year.value, month.value), fetchTasks()])
    diaries.value = diaryData
    tasks.value = taskData
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
    if (selectedDiary.value) {
      const updated = await updateDiary(selectedDiary.value.id, {
        date: selectedDate.value,
        title: form.title,
        content: form.content,
      })
      const idx = diaries.value.findIndex((d) => d.id === updated.id)
      if (idx !== -1) diaries.value[idx] = updated
    } else {
      const created = await createDiary({
        date: selectedDate.value,
        title: form.title,
        content: form.content,
      })
      diaries.value.push(created)
    }
    showDialog.value = false
  } catch {
    errorMsg.value = '保存に失敗しました。'
  } finally {
    saving.value = false
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
