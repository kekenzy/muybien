<template>
  <div class="max-w-5xl mx-auto px-6 py-10">
    <div class="mb-6">
      <h2 class="text-xl font-bold">予約管理</h2>
      <p class="text-sm text-white/60 mt-1">顧客ポータルから入った予約の確認・営業時間の設定</p>
    </div>

    <div class="mb-6 flex gap-2">
      <button
        type="button"
        class="text-sm px-4 py-2 rounded-full border transition-colors"
        :class="activeTab === 'list' ? 'bg-primary text-black border-primary' : 'border-white/20 text-white/70 hover:text-white'"
        @click="activeTab = 'list'"
      >
        予約一覧
      </button>
      <button
        type="button"
        class="text-sm px-4 py-2 rounded-full border transition-colors"
        :class="activeTab === 'settings' ? 'bg-primary text-black border-primary' : 'border-white/20 text-white/70 hover:text-white'"
        @click="activeTab = 'settings'"
      >
        営業時間設定
      </button>
    </div>

    <div v-if="errorMsg" class="mb-6 bg-red-500/10 border border-red-500/30 text-red-300 rounded-xl p-4 text-sm">
      {{ errorMsg }}
    </div>

    <template v-if="activeTab === 'list'">
      <div v-if="loadingList" class="text-center text-white/60 py-20 text-sm">読み込み中...</div>
      <div v-else-if="sortedReservations.length === 0" class="text-center text-white/60 py-20 text-sm">
        予約はありません
      </div>
      <div v-else class="overflow-x-auto rounded-2xl border border-white/10">
        <table class="w-full text-sm">
          <thead class="bg-white/5 text-white/70 text-xs">
            <tr>
              <th class="px-4 py-3 text-left font-medium">顧客</th>
              <th class="px-4 py-3 text-left font-medium">日時</th>
              <th class="px-4 py-3 text-left font-medium">ステータス</th>
              <th class="px-4 py-3 text-left font-medium">備考</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-white/10">
            <tr
              v-for="reservation in sortedReservations"
              :key="reservation.id"
              class="cursor-pointer hover:bg-white/5"
              @click="openDetail(reservation)"
            >
              <td class="px-4 py-3 whitespace-nowrap">{{ reservation.customer_name }}</td>
              <td class="px-4 py-3 whitespace-nowrap">{{ formatDateTime(reservation.start_at) }}</td>
              <td class="px-4 py-3">
                <span class="text-xs px-3 py-1 rounded-full border" :class="statusStyle(reservation.status)">
                  {{ reservation.status === 'confirmed' ? '確定' : 'キャンセル' }}
                </span>
              </td>
              <td class="px-4 py-3 max-w-[240px] truncate text-white/80">{{ reservation.note || '-' }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </template>

    <template v-else>
      <div v-if="loadingSettings" class="text-center text-white/60 py-20 text-sm">読み込み中...</div>
      <div v-else class="space-y-8">
        <div class="grid grid-cols-3 gap-4 max-w-xl">
          <div>
            <label class="block text-xs text-white/60 mb-1">予約単位(分)</label>
            <input
              v-model.number="settingsForm.slot_minutes"
              type="number"
              min="5"
              :disabled="!canWrite('reservations')"
              class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50"
            />
          </div>
          <div>
            <label class="block text-xs text-white/60 mb-1">最短受付(時間前)</label>
            <input
              v-model.number="settingsForm.min_notice_hours"
              type="number"
              min="0"
              :disabled="!canWrite('reservations')"
              class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50"
            />
          </div>
          <div>
            <label class="block text-xs text-white/60 mb-1">予約可能日数</label>
            <input
              v-model.number="settingsForm.max_advance_days"
              type="number"
              min="1"
              :disabled="!canWrite('reservations')"
              class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50"
            />
          </div>
        </div>

        <div>
          <div class="flex items-center justify-between mb-3">
            <h3 class="font-semibold">営業時間</h3>
            <button
              v-if="canWrite('reservations')"
              type="button"
              class="text-xs text-primary hover:opacity-80 transition-opacity"
              @click="addRule"
            >
              + 追加
            </button>
          </div>
          <div v-if="rulesForm.length === 0" class="text-sm text-white/50">営業時間が設定されていません。</div>
          <div v-for="(rule, idx) in rulesForm" :key="idx" class="flex items-center gap-3 mb-2">
            <select
              v-model.number="rule.weekday"
              :disabled="!canWrite('reservations')"
              class="rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50"
            >
              <option v-for="(label, i) in weekdayLabels" :key="i" :value="i">{{ label }}曜日</option>
            </select>
            <input
              v-model="rule.start_time"
              type="time"
              :disabled="!canWrite('reservations')"
              class="rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50"
            />
            <span class="text-white/50">〜</span>
            <input
              v-model="rule.end_time"
              type="time"
              :disabled="!canWrite('reservations')"
              class="rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50"
            />
            <button
              v-if="canWrite('reservations')"
              type="button"
              class="text-xs text-red-400/70 hover:text-red-400 transition-colors"
              @click="rulesForm.splice(idx, 1)"
            >
              削除
            </button>
          </div>
        </div>

        <button
          v-if="canWrite('reservations')"
          type="button"
          class="text-sm px-4 py-2 rounded-full bg-primary text-black font-medium hover:opacity-90 transition-opacity disabled:opacity-50"
          :disabled="saving"
          @click="saveSettings"
        >
          {{ saving ? '保存中...' : '保存する' }}
        </button>
      </div>
    </template>

    <div
      v-if="showDetail && selectedReservation"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4"
      @click.self="closeDetail"
    >
      <div class="w-full max-w-lg rounded-2xl border border-white/10 bg-[#0c1220] p-8 space-y-4">
        <div class="flex items-center justify-between">
          <h3 class="font-semibold text-base">予約詳細</h3>
          <button type="button" class="text-white/60 hover:text-white transition-colors" @click="closeDetail">
            ✕
          </button>
        </div>
        <dl class="text-sm space-y-2">
          <div class="flex justify-between"><dt class="text-white/60">顧客</dt><dd>{{ selectedReservation.customer_name }}</dd></div>
          <div class="flex justify-between"><dt class="text-white/60">メール</dt><dd>{{ selectedReservation.customer_email }}</dd></div>
          <div class="flex justify-between"><dt class="text-white/60">日時</dt><dd>{{ formatDateTime(selectedReservation.start_at) }} 〜 {{ formatTime(selectedReservation.end_at) }}</dd></div>
          <div class="flex justify-between"><dt class="text-white/60">ステータス</dt><dd>{{ selectedReservation.status === 'confirmed' ? '確定' : 'キャンセル' }}</dd></div>
          <div v-if="selectedReservation.note"><dt class="text-white/60 mb-1">備考</dt><dd class="whitespace-pre-wrap">{{ selectedReservation.note }}</dd></div>
        </dl>
        <div v-if="canWrite('reservations') && selectedReservation.status === 'confirmed'" class="pt-2">
          <button
            type="button"
            class="text-xs text-red-400/70 hover:text-red-400 transition-colors"
            @click="handleCancelReservation"
          >
            この予約をキャンセルする
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import {
  cancelLabReservation,
  fetchLabReservations,
  fetchReservationSettings,
  updateReservationSettings,
  type AvailabilityRule,
  type LabReservation,
  type ReservationSettings,
} from '../../lib/api'
import { canWrite } from '../../lib/permissions'

const weekdayLabels = ['月', '火', '水', '木', '金', '土', '日']

const activeTab = ref<'list' | 'settings'>('list')
const errorMsg = ref('')

const reservations = ref<LabReservation[]>([])
const loadingList = ref(true)
const showDetail = ref(false)
const selectedReservation = ref<LabReservation | null>(null)

const loadingSettings = ref(true)
const saving = ref(false)
const settingsForm = ref<ReservationSettings>({ slot_minutes: 60, min_notice_hours: 24, max_advance_days: 60 })
const rulesForm = ref<AvailabilityRule[]>([])

function formatDateTime(iso: string): string {
  return new Date(iso).toLocaleString('ja-JP', {
    year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit',
  })
}

function formatTime(iso: string): string {
  return new Date(iso).toLocaleTimeString('ja-JP', { hour: '2-digit', minute: '2-digit' })
}

function statusStyle(status: string): string {
  return status === 'confirmed'
    ? 'border-green-500/40 text-green-400 bg-green-500/10'
    : 'border-white/20 text-white/50'
}

const sortedReservations = computed(() => [...reservations.value].sort((a, b) => b.start_at.localeCompare(a.start_at)))

async function loadReservations() {
  loadingList.value = true
  errorMsg.value = ''
  try {
    reservations.value = await fetchLabReservations()
  } catch {
    errorMsg.value = '予約一覧の取得に失敗しました。'
  } finally {
    loadingList.value = false
  }
}

async function loadSettings() {
  loadingSettings.value = true
  errorMsg.value = ''
  try {
    const data = await fetchReservationSettings()
    settingsForm.value = { ...data.settings }
    rulesForm.value = data.rules.map((r) => ({ ...r }))
  } catch {
    errorMsg.value = '営業時間設定の取得に失敗しました。'
  } finally {
    loadingSettings.value = false
  }
}

function addRule() {
  rulesForm.value.push({ id: 0, weekday: 0, start_time: '10:00', end_time: '18:00', is_active: true })
}

async function saveSettings() {
  saving.value = true
  errorMsg.value = ''
  try {
    const data = await updateReservationSettings({ settings: settingsForm.value, rules: rulesForm.value })
    settingsForm.value = { ...data.settings }
    rulesForm.value = data.rules.map((r) => ({ ...r }))
  } catch {
    errorMsg.value = '保存に失敗しました。'
  } finally {
    saving.value = false
  }
}

function openDetail(reservation: LabReservation) {
  selectedReservation.value = reservation
  showDetail.value = true
}

function closeDetail() {
  showDetail.value = false
  selectedReservation.value = null
}

async function handleCancelReservation() {
  if (!selectedReservation.value) return
  if (!confirm('この予約をキャンセルしますか？')) return
  try {
    await cancelLabReservation(selectedReservation.value.id)
    selectedReservation.value.status = 'cancelled'
    const idx = reservations.value.findIndex((r) => r.id === selectedReservation.value!.id)
    if (idx !== -1) reservations.value[idx] = { ...reservations.value[idx], status: 'cancelled' }
    closeDetail()
  } catch {
    errorMsg.value = 'キャンセルに失敗しました。'
  }
}

onMounted(() => {
  loadReservations()
  loadSettings()
})
</script>
