<template>
  <div class="max-w-5xl mx-auto px-4 sm:px-6 py-10">
    <div class="mb-6 flex items-center justify-between">
      <div>
        <h2 class="text-xl font-bold">Daily</h2>
        <p class="text-sm text-white/60 mt-1">毎日やることを、カレンダーの印をクリックしてチェックする</p>
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

    <div class="mb-6 flex flex-wrap items-center gap-2">
      <button
        v-for="item in items"
        :key="item.id"
        type="button"
        class="flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-xs transition-colors"
        :class="item.is_active ? 'border-white/15 hover:border-white/40' : 'border-white/10 opacity-40 hover:opacity-70'"
        :disabled="!canWrite('daily')"
        @click="openItemDialog(item)"
      >
        <span :style="{ color: item.color }">{{ MARKS[item.mark] }}</span>
        <span>{{ item.title }}</span>
        <span class="text-white/50">{{ monthCount(item.id) }}回</span>
      </button>
      <button
        v-if="canWrite('daily')"
        type="button"
        class="rounded-full border border-dashed border-white/25 px-3 py-1.5 text-xs text-white/70 hover:text-white hover:border-white/50 transition-colors"
        @click="openItemDialog(null)"
      >
        ＋ 項目を追加
      </button>
      <span v-if="!loading && !items.length && !canWrite('daily')" class="text-sm text-white/60">
        項目が登録されていません。
      </span>
    </div>

    <div v-if="loading" class="text-center text-white/60 py-10 text-sm">読み込み中...</div>

    <div v-else class="grid grid-cols-7 gap-1">
      <div v-for="w in weekdays" :key="w" class="text-xs text-white/60 text-center py-2">{{ w }}</div>
      <div
        v-for="day in calendarDays"
        :key="day.iso"
        class="min-h-[76px] rounded-lg border p-1.5 flex flex-col gap-1 overflow-hidden"
        :class="dayStyle(day)"
      >
        <div class="flex items-center justify-between">
          <span class="text-xs" :class="day.iso === todayIso ? 'font-bold text-primary' : ''">
            {{ day.date.getDate() }}
          </span>
          <span v-if="activeItems.length && day.checkedCount" class="text-[10px] text-white/50">
            {{ day.checkedCount === activeItems.length ? '🎉' : `${day.checkedCount}/${activeItems.length}` }}
          </span>
        </div>
        <div class="flex flex-wrap gap-x-1 gap-y-0.5 sm:flex-col sm:gap-0.5">
          <button
            v-for="item in activeItems"
            :key="item.id"
            type="button"
            class="flex items-center gap-1 min-w-0 rounded text-left leading-none transition-opacity disabled:cursor-default"
            :class="isFuture(day) ? 'opacity-30' : 'hover:opacity-80'"
            :disabled="!canWrite('daily') || isFuture(day) || pendingKeys.has(checkKey(item.id, day.iso))"
            :title="`${item.title}${isChecked(item.id, day.iso) ? '（済）' : ''}`"
            @click="toggle(item, day.iso)"
          >
            <span
              class="text-sm sm:text-xs shrink-0"
              :style="isChecked(item.id, day.iso) ? { color: item.color } : undefined"
              :class="isChecked(item.id, day.iso) ? '' : 'text-white/15'"
            >
              {{ MARKS[item.mark] }}
            </span>
            <span
              class="hidden sm:inline truncate text-[10px]"
              :class="isChecked(item.id, day.iso) ? 'text-white/85' : 'text-white/35'"
            >
              {{ item.title }}
            </span>
          </button>
        </div>
      </div>
    </div>

    <div
      v-if="showItemDialog"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4"
      @click.self="showItemDialog = false"
    >
      <div class="w-full max-w-md rounded-2xl border border-white/10 bg-[#0c1220] p-6 space-y-5">
        <div class="flex items-center justify-between">
          <h3 class="font-semibold text-base">{{ editingItem ? '項目を編集' : '項目を追加' }}</h3>
          <button type="button" class="text-white/60 hover:text-white transition-colors" @click="showItemDialog = false">
            ✕
          </button>
        </div>

        <div>
          <label class="block text-xs text-white/60 mb-1">やること</label>
          <input
            v-model="itemForm.title"
            type="text"
            maxlength="100"
            placeholder="例：筋トレ、英語30分"
            class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2.5 text-sm focus:outline-none focus:border-primary/60"
          />
        </div>

        <div>
          <label class="block text-xs text-white/60 mb-2">印</label>
          <div class="flex flex-wrap gap-2">
            <button
              v-for="(symbol, key) in MARKS"
              :key="key"
              type="button"
              class="w-9 h-9 rounded-lg border text-lg transition-colors"
              :class="itemForm.mark === key ? 'border-white/60 bg-white/10' : 'border-white/10 hover:border-white/30'"
              :style="{ color: itemForm.color }"
              @click="itemForm.mark = key"
            >
              {{ symbol }}
            </button>
          </div>
        </div>

        <div>
          <label class="block text-xs text-white/60 mb-2">色</label>
          <div class="flex flex-wrap items-center gap-2">
            <button
              v-for="color in COLORS"
              :key="color"
              type="button"
              class="w-7 h-7 rounded-full border-2 transition-transform"
              :class="itemForm.color === color ? 'border-white scale-110' : 'border-transparent'"
              :style="{ backgroundColor: color }"
              :aria-label="color"
              @click="itemForm.color = color"
            />
            <input
              v-model="itemForm.color"
              type="color"
              class="w-7 h-7 rounded-full bg-transparent border border-white/20 cursor-pointer"
              aria-label="その他の色"
            />
          </div>
        </div>

        <label v-if="editingItem" class="flex items-center gap-2 text-sm text-white/80">
          <input v-model="itemForm.is_active" type="checkbox" class="accent-primary" />
          カレンダーに表示する（オフにしても過去のチェックは残ります）
        </label>

        <div class="flex items-center justify-between pt-2">
          <button
            v-if="editingItem"
            type="button"
            class="text-xs text-red-400/70 hover:text-red-400 transition-colors"
            @click="removeItem"
          >
            削除
          </button>
          <span v-else />
          <button
            type="button"
            class="text-sm px-4 py-2 rounded-full bg-primary text-black font-medium hover:opacity-90 transition-opacity disabled:opacity-50"
            :disabled="!itemForm.title.trim() || saving"
            @click="saveItem"
          >
            {{ editingItem ? '更新する' : '追加する' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import {
  createDailyItem,
  deleteDailyItem,
  fetchDailyChecks,
  fetchDailyItems,
  toggleDailyCheck,
  updateDailyItem,
  type DailyItem,
  type DailyMark,
} from '../../lib/api'
import { canWrite } from '../../lib/permissions'

const weekdays = ['日', '月', '火', '水', '木', '金', '土']

const MARKS: Record<DailyMark, string> = {
  star: '★',
  circle: '●',
  heart: '♥',
  diamond: '◆',
  triangle: '▲',
  check: '✔',
}

const COLORS = ['#facc15', '#f97316', '#ef4444', '#ec4899', '#a855f7', '#3b82f6', '#22d3ee', '#22c55e']

const today = new Date()
const todayIso = toIso(today)
const year = ref(today.getFullYear())
const month = ref(today.getMonth() + 1)

const items = ref<DailyItem[]>([])
// "itemId:YYYY-MM-DD" の集合でチェック済みを持つ
const checked = ref(new Set<string>())
const pendingKeys = ref(new Set<string>())
const loading = ref(true)
const saving = ref(false)
const errorMsg = ref('')

const showItemDialog = ref(false)
const editingItem = ref<DailyItem | null>(null)
const itemForm = reactive({ title: '', color: COLORS[0], mark: 'star' as DailyMark, is_active: true })

const activeItems = computed(() => items.value.filter((item) => item.is_active))

interface CalendarDay {
  date: Date
  iso: string
  inMonth: boolean
  checkedCount: number
}

function toIso(date: Date): string {
  const y = date.getFullYear()
  const m = String(date.getMonth() + 1).padStart(2, '0')
  const d = String(date.getDate()).padStart(2, '0')
  return `${y}-${m}-${d}`
}

function checkKey(itemId: number, iso: string): string {
  return `${itemId}:${iso}`
}

function isChecked(itemId: number, iso: string): boolean {
  return checked.value.has(checkKey(itemId, iso))
}

function isFuture(day: CalendarDay): boolean {
  return day.iso > todayIso
}

function monthCount(itemId: number): number {
  let count = 0
  for (const key of checked.value) {
    if (key.startsWith(`${itemId}:`)) count++
  }
  return count
}

const calendarDays = computed<CalendarDay[]>(() => {
  const firstOfMonth = new Date(year.value, month.value - 1, 1)
  const gridStart = new Date(year.value, month.value - 1, 1 - firstOfMonth.getDay())

  const days: CalendarDay[] = []
  for (let i = 0; i < 42; i++) {
    const date = new Date(gridStart)
    date.setDate(gridStart.getDate() + i)
    const iso = toIso(date)
    const inMonth = date.getMonth() === month.value - 1
    days.push({
      date,
      iso,
      inMonth,
      checkedCount: inMonth ? activeItems.value.filter((item) => isChecked(item.id, iso)).length : 0,
    })
  }
  return days
})

function dayStyle(day: CalendarDay): string {
  const classes: string[] = []
  classes.push(day.inMonth ? 'text-white' : 'text-white/45 opacity-40 pointer-events-none')
  if (day.inMonth && activeItems.value.length && day.checkedCount === activeItems.value.length) {
    classes.push('border-primary/60 bg-primary/10')
  } else if (day.iso === todayIso) {
    classes.push('border-primary/40')
  } else {
    classes.push('border-white/10')
  }
  return classes.join(' ')
}

async function loadData() {
  loading.value = true
  errorMsg.value = ''
  try {
    const [itemData, checkData] = await Promise.all([
      fetchDailyItems(),
      fetchDailyChecks(year.value, month.value),
    ])
    items.value = itemData
    checked.value = new Set(checkData.map((c) => checkKey(c.item, c.date)))
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

watch([year, month], loadData)

function setChecked(key: string, value: boolean) {
  const next = new Set(checked.value)
  if (value) next.add(key)
  else next.delete(key)
  checked.value = next
}

async function toggle(item: DailyItem, iso: string) {
  const key = checkKey(item.id, iso)
  const before = checked.value.has(key)
  // 先に見た目を切り替え、失敗したら戻す
  setChecked(key, !before)
  pendingKeys.value = new Set(pendingKeys.value).add(key)
  try {
    const result = await toggleDailyCheck(item.id, iso)
    setChecked(key, result.checked)
  } catch {
    setChecked(key, before)
    errorMsg.value = 'チェックの更新に失敗しました。'
  } finally {
    const next = new Set(pendingKeys.value)
    next.delete(key)
    pendingKeys.value = next
  }
}

function openItemDialog(item: DailyItem | null) {
  editingItem.value = item
  itemForm.title = item?.title ?? ''
  itemForm.color = item?.color ?? COLORS[items.value.length % COLORS.length]
  itemForm.mark = item?.mark ?? 'star'
  itemForm.is_active = item?.is_active ?? true
  showItemDialog.value = true
}

async function saveItem() {
  saving.value = true
  errorMsg.value = ''
  try {
    const input = {
      title: itemForm.title.trim(),
      color: itemForm.color,
      mark: itemForm.mark,
      is_active: itemForm.is_active,
    }
    if (editingItem.value) {
      const updated = await updateDailyItem(editingItem.value.id, input)
      items.value = items.value.map((i) => (i.id === updated.id ? updated : i))
    } else {
      const order = Math.max(0, ...items.value.map((i) => i.order)) + 1
      const created = await createDailyItem({ ...input, order })
      items.value = [...items.value, created]
    }
    showItemDialog.value = false
  } catch {
    errorMsg.value = '保存に失敗しました。'
  } finally {
    saving.value = false
  }
}

async function removeItem() {
  const item = editingItem.value
  if (!item) return
  if (!confirm(`「${item.title}」を削除しますか？過去のチェック記録も削除されます。\n記録を残したい場合は「カレンダーに表示する」をオフにしてください。`)) return
  try {
    await deleteDailyItem(item.id)
    items.value = items.value.filter((i) => i.id !== item.id)
    checked.value = new Set([...checked.value].filter((key) => !key.startsWith(`${item.id}:`)))
    showItemDialog.value = false
  } catch {
    errorMsg.value = '削除に失敗しました。'
  }
}

onMounted(loadData)
</script>
