<template>
  <div class="max-w-4xl mx-auto px-6 py-10 space-y-10">
    <div>
      <div class="mb-8 flex items-center justify-between">
        <div>
          <h2 class="text-xl font-bold">予約管理</h2>
          <p class="text-sm text-white/60 mt-1">カレンダーから空き枠を選んで打ち合わせを予約する</p>
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
          class="relative min-h-[64px] rounded-lg border p-1.5 flex flex-col items-start gap-0.5 overflow-hidden text-left transition-colors"
          :class="dayStyle(day)"
          @click="openCreateDialog(day.iso)"
        >
          <span class="text-xs">{{ day.date.getDate() }}</span>
          <span v-if="day.count > 0" class="w-full truncate text-[10px] text-primary">
            📅 予約{{ day.count }}件
          </span>
        </button>
      </div>
    </div>

    <div>
      <h3 class="font-semibold mb-3">今後の予約</h3>
      <div v-if="upcomingAppointments.length === 0" class="text-sm text-white/50">予約はありません。</div>
      <div class="space-y-2">
        <button
          v-for="a in upcomingAppointments"
          :key="a.id"
          type="button"
          class="w-full text-left rounded-lg border border-white/10 hover:border-white/30 px-4 py-3 transition-colors"
          @click="openManageDialog(a)"
        >
          <div class="text-sm font-medium">{{ formatDateTime(a.start_at) }} 〜 {{ formatTime(a.end_at) }}</div>
          <div v-if="a.note" class="text-xs text-white/60 mt-1 truncate">{{ a.note }}</div>
        </button>
      </div>
    </div>

    <div v-if="pastAppointments.length > 0">
      <h3 class="font-semibold mb-3">過去の予約</h3>
      <div class="space-y-2">
        <div
          v-for="a in pastAppointments"
          :key="a.id"
          class="rounded-lg border border-white/10 px-4 py-3 text-white/60"
        >
          <div class="text-sm">
            {{ formatDateTime(a.start_at) }} 〜 {{ formatTime(a.end_at) }}
            <span v-if="a.status === 'cancelled'" class="text-red-400/80 text-xs ml-2">キャンセル済み</span>
          </div>
          <div v-if="a.note" class="text-xs mt-1 truncate">{{ a.note }}</div>
        </div>
      </div>
    </div>

    <div
      v-if="showDialog"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4"
      @click.self="closeDialog"
    >
      <div class="w-full max-w-2xl max-h-[90vh] overflow-y-auto rounded-2xl border border-white/10 bg-[#0c1220] p-8 space-y-5">
        <div class="flex items-center justify-between">
          <h3 class="font-semibold text-base">{{ editingAppointment ? '予約の変更' : '新しい予約' }}</h3>
          <button type="button" class="text-white/60 hover:text-white transition-colors" @click="closeDialog">
            ✕
          </button>
        </div>

        <div v-if="dialogErrorMsg" class="bg-red-500/10 border border-red-500/30 text-red-300 rounded-xl p-3 text-sm">
          {{ dialogErrorMsg }}
        </div>

        <div>
          <label class="block text-xs text-white/60 mb-1">日付</label>
          <input
            v-model="pickerDate"
            type="date"
            class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2.5 text-sm focus:outline-none focus:border-primary/60"
            @change="loadSlotsForPicker"
          />
        </div>

        <div>
          <label class="block text-xs text-white/60 mb-2">時間帯</label>
          <div v-if="slotsLoading" class="text-sm text-white/50">読み込み中...</div>
          <div v-else-if="pickerSlots.length === 0" class="text-sm text-white/50">この日は空き枠がありません。</div>
          <div v-else class="grid grid-cols-3 gap-2">
            <button
              v-for="slot in pickerSlots"
              :key="slot.start_at"
              type="button"
              class="rounded-lg border px-2 py-2 text-sm transition-colors"
              :class="selectedSlot === slot.start_at
                ? 'border-primary bg-primary/10 text-white'
                : 'border-white/10 text-white/70 hover:border-white/30'"
              @click="selectedSlot = slot.start_at"
            >
              {{ formatTime(slot.start_at) }}
            </button>
          </div>
        </div>

        <div v-if="!editingAppointment">
          <label class="block text-xs text-white/60 mb-1">備考</label>
          <textarea
            v-model="noteInput"
            rows="3"
            placeholder="ご相談内容など（任意）"
            class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2.5 text-sm focus:outline-none focus:border-primary/60"
          />
        </div>

        <div class="flex items-center justify-between pt-2">
          <button
            v-if="editingAppointment"
            type="button"
            class="text-xs text-red-400/70 hover:text-red-400 transition-colors"
            @click="handleCancelAppointment"
          >
            予約をキャンセル
          </button>
          <span v-else />
          <button
            type="button"
            class="text-sm px-4 py-2 rounded-full bg-primary text-black font-medium hover:opacity-90 transition-opacity disabled:opacity-50"
            :disabled="!selectedSlot || saving"
            @click="handleSubmit"
          >
            {{ editingAppointment ? '変更する' : '予約する' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import {
  cancelAppointment,
  createAppointment,
  fetchAppointments,
  fetchAvailability,
  rescheduleAppointment,
  type Appointment,
  type AvailabilitySlot,
} from '../../lib/portalApi'

const weekdays = ['日', '月', '火', '水', '木', '金', '土']

const today = new Date()
const year = ref(today.getFullYear())
const month = ref(today.getMonth() + 1)

const appointments = ref<Appointment[]>([])
const loading = ref(true)
const saving = ref(false)
const errorMsg = ref('')
const dialogErrorMsg = ref('')

const showDialog = ref(false)
const editingAppointment = ref<Appointment | null>(null)
const pickerDate = ref('')
const pickerSlots = ref<AvailabilitySlot[]>([])
const selectedSlot = ref<string | null>(null)
const slotsLoading = ref(false)
const noteInput = ref('')

interface CalendarDay {
  date: Date
  iso: string
  inMonth: boolean
  count: number
}

function toIso(date: Date): string {
  const y = date.getFullYear()
  const m = String(date.getMonth() + 1).padStart(2, '0')
  const d = String(date.getDate()).padStart(2, '0')
  return `${y}-${m}-${d}`
}

function formatDateTime(iso: string): string {
  return new Date(iso).toLocaleString('ja-JP', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })
}

function formatTime(iso: string): string {
  return new Date(iso).toLocaleTimeString('ja-JP', { hour: '2-digit', minute: '2-digit' })
}

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
      count: appointments.value.filter((a) => a.status === 'confirmed' && a.start_at.startsWith(iso)).length,
    })
  }
  return days
})

const upcomingAppointments = computed(() =>
  appointments.value
    .filter((a) => a.status === 'confirmed' && new Date(a.start_at) >= new Date())
    .sort((a, b) => a.start_at.localeCompare(b.start_at)),
)

const pastAppointments = computed(() =>
  appointments.value
    .filter((a) => a.status === 'cancelled' || new Date(a.start_at) < new Date())
    .sort((a, b) => b.start_at.localeCompare(a.start_at)),
)

function dayStyle(day: CalendarDay): string {
  const classes: string[] = []
  classes.push(day.inMonth ? 'text-white' : 'text-white/45')
  classes.push('border-white/10 hover:border-white/30')
  return classes.join(' ')
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

async function loadAppointments() {
  loading.value = true
  errorMsg.value = ''
  try {
    appointments.value = await fetchAppointments()
  } catch {
    errorMsg.value = '予約情報の取得に失敗しました。'
  } finally {
    loading.value = false
  }
}

async function loadSlotsForPicker() {
  if (!pickerDate.value) return
  slotsLoading.value = true
  selectedSlot.value = null
  dialogErrorMsg.value = ''
  try {
    pickerSlots.value = await fetchAvailability(pickerDate.value, pickerDate.value)
  } catch {
    dialogErrorMsg.value = '空き枠の取得に失敗しました。'
  } finally {
    slotsLoading.value = false
  }
}

function openCreateDialog(iso: string) {
  editingAppointment.value = null
  pickerDate.value = iso
  noteInput.value = ''
  dialogErrorMsg.value = ''
  showDialog.value = true
  loadSlotsForPicker()
}

function openManageDialog(appointment: Appointment) {
  editingAppointment.value = appointment
  pickerDate.value = appointment.start_at.slice(0, 10)
  dialogErrorMsg.value = ''
  showDialog.value = true
  loadSlotsForPicker()
}

function closeDialog() {
  showDialog.value = false
  editingAppointment.value = null
}

async function handleSubmit() {
  if (!selectedSlot.value) return
  saving.value = true
  dialogErrorMsg.value = ''
  try {
    if (editingAppointment.value) {
      const updated = await rescheduleAppointment(editingAppointment.value.id, selectedSlot.value)
      const idx = appointments.value.findIndex((a) => a.id === updated.id)
      if (idx !== -1) appointments.value[idx] = updated
    } else {
      const created = await createAppointment(selectedSlot.value, noteInput.value)
      appointments.value.push(created)
    }
    closeDialog()
  } catch (e: any) {
    dialogErrorMsg.value = e?.response?.data?.detail ?? '保存に失敗しました。'
  } finally {
    saving.value = false
  }
}

async function handleCancelAppointment() {
  if (!editingAppointment.value) return
  if (!confirm('この予約をキャンセルしますか？')) return
  try {
    await cancelAppointment(editingAppointment.value.id)
    const idx = appointments.value.findIndex((a) => a.id === editingAppointment.value!.id)
    if (idx !== -1) appointments.value[idx] = { ...appointments.value[idx], status: 'cancelled' }
    closeDialog()
  } catch {
    dialogErrorMsg.value = 'キャンセルに失敗しました。'
  }
}

onMounted(loadAppointments)
</script>
