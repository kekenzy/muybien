<template>
  <div class="max-w-5xl mx-auto px-6 py-10">
    <div class="mb-6">
      <h2 class="text-xl font-bold">お問い合わせ一覧</h2>
      <p class="text-sm text-white/60 mt-1">コンタクトフォームから届いたメッセージ</p>
    </div>

    <div v-if="errorMsg" class="mb-6 bg-red-500/10 border border-red-500/30 text-red-300 rounded-xl p-4 text-sm">
      {{ errorMsg }}
    </div>

    <div class="mb-4 flex flex-wrap items-center gap-3">
      <input
        v-model="searchQuery"
        type="text"
        placeholder="お名前・メール・件名で検索"
        class="flex-1 min-w-[200px] rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm focus:outline-none focus:border-primary/60"
      />
      <select
        v-model="statusFilter"
        class="rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm focus:outline-none focus:border-primary/60"
      >
        <option value="all">すべて</option>
        <option value="unreplied">未返信</option>
        <option value="replied">返信済み</option>
      </select>
    </div>

    <div v-if="loading" class="text-center text-white/60 py-20 text-sm">読み込み中...</div>

    <div v-else-if="sortedContacts.length === 0" class="text-center text-white/60 py-20 text-sm">
      該当するお問い合わせはありません
    </div>

    <template v-else>
      <div class="overflow-x-auto rounded-2xl border border-white/10">
        <table class="w-full text-sm">
          <thead class="bg-white/5 text-white/70 text-xs">
            <tr>
              <th class="px-4 py-3 text-left font-medium cursor-pointer select-none" @click="sortBy('created_at')">
                受信日時{{ sortIndicator('created_at') }}
              </th>
              <th class="px-4 py-3 text-left font-medium cursor-pointer select-none" @click="sortBy('name')">
                お名前{{ sortIndicator('name') }}
              </th>
              <th class="px-4 py-3 text-left font-medium">メールアドレス</th>
              <th class="px-4 py-3 text-left font-medium cursor-pointer select-none" @click="sortBy('subject')">
                件名{{ sortIndicator('subject') }}
              </th>
              <th class="px-4 py-3 text-left font-medium">ステータス</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-white/10">
            <tr
              v-for="contact in pagedContacts"
              :key="contact.id"
              class="cursor-pointer hover:bg-white/5"
              @click="openDetail(contact)"
            >
              <td class="px-4 py-3 whitespace-nowrap text-white/80">{{ formatDate(contact.created_at) }}</td>
              <td class="px-4 py-3">{{ contact.name }}</td>
              <td class="px-4 py-3 text-white/80">
                <a :href="`mailto:${contact.email}`" class="text-primary hover:underline" @click.stop>{{ contact.email }}</a>
              </td>
              <td class="px-4 py-3 max-w-[220px] truncate">{{ contact.subject }}</td>
              <td class="px-4 py-3">
                <button
                  type="button"
                  class="text-xs px-3 py-1 rounded-full border transition-colors"
                  :class="contact.is_replied
                    ? 'border-green-500/40 text-green-400 bg-green-500/10'
                    : 'border-white/20 text-white/70 hover:border-white/40'"
                  @click.stop="toggleReplied(contact)"
                >
                  {{ contact.is_replied ? '返信済み' : '未返信' }}
                </button>
              </td>
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
      v-if="selectedContact"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4"
      @click.self="closeDetail"
    >
      <div class="w-full max-w-lg rounded-2xl border border-white/10 bg-[#0c1220] p-6 space-y-4">
        <div class="flex items-start justify-between gap-3">
          <div>
            <div class="font-semibold">{{ selectedContact.name }}</div>
            <a :href="`mailto:${selectedContact.email}`" class="text-sm text-primary hover:underline">
              {{ selectedContact.email }}
            </a>
          </div>
          <button type="button" class="text-white/60 hover:text-white transition-colors" @click="closeDetail">✕</button>
        </div>
        <time class="block text-xs text-white/60">{{ formatDate(selectedContact.created_at) }}</time>
        <div class="text-sm font-medium text-white/90">{{ selectedContact.subject }}</div>
        <p class="text-sm text-white/80 leading-relaxed whitespace-pre-wrap">{{ selectedContact.message }}</p>
        <div class="flex flex-wrap items-center gap-2">
          <button
            type="button"
            class="text-xs px-3 py-1 rounded-full border transition-colors disabled:opacity-50"
            :class="selectedContact.is_replied
              ? 'border-green-500/40 text-green-400 bg-green-500/10'
              : 'border-white/20 text-white/70 hover:border-white/40'"
            :disabled="!canWrite('contacts')"
            @click="toggleReplied(selectedContact)"
          >
            {{ selectedContact.is_replied ? '返信済み' : '未返信' }}
          </button>
          <button
            v-if="!selectedContact.customer_id && canWrite('contacts')"
            type="button"
            class="text-xs px-3 py-1 rounded-full border border-primary/40 text-primary hover:bg-primary/10 transition-colors disabled:opacity-50"
            :disabled="registering"
            @click="registerCustomer(selectedContact)"
          >
            {{ registering ? '登録中...' : '+ 顧客管理に登録' }}
          </button>
          <span
            v-else
            class="text-xs px-3 py-1 rounded-full border border-green-500/40 text-green-400 bg-green-500/10"
          >
            顧客登録済み
          </span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { createCustomer, fetchContacts, updateContact, type ContactMessage } from '../../lib/api'
import { canWrite } from '../../lib/permissions'

type SortKey = 'created_at' | 'name' | 'subject'
type StatusFilter = 'all' | 'unreplied' | 'replied'

const router = useRouter()
const contacts = ref<ContactMessage[]>([])
const loading = ref(true)
const errorMsg = ref('')
const selectedContact = ref<ContactMessage | null>(null)
const registering = ref(false)

const searchQuery = ref('')
const statusFilter = ref<StatusFilter>('all')
const sortKey = ref<SortKey>('created_at')
const sortAsc = ref(false)
const page = ref(1)
const pageSize = 20

function formatDate(iso: string): string {
  return new Date(iso).toLocaleString('ja-JP', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  })
}

const filteredContacts = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  return contacts.value.filter((c) => {
    if (statusFilter.value === 'unreplied' && c.is_replied) return false
    if (statusFilter.value === 'replied' && !c.is_replied) return false
    if (!query) return true
    return (
      c.name.toLowerCase().includes(query) ||
      c.email.toLowerCase().includes(query) ||
      c.subject.toLowerCase().includes(query)
    )
  })
})

const sortedContacts = computed(() => {
  const list = [...filteredContacts.value]
  list.sort((a, b) => {
    const av = a[sortKey.value]
    const bv = b[sortKey.value]
    if (av < bv) return sortAsc.value ? -1 : 1
    if (av > bv) return sortAsc.value ? 1 : -1
    return 0
  })
  return list
})

const totalPages = computed(() => Math.max(1, Math.ceil(sortedContacts.value.length / pageSize)))

const pagedContacts = computed(() => {
  const start = (page.value - 1) * pageSize
  return sortedContacts.value.slice(start, start + pageSize)
})

const rangeLabel = computed(() => {
  const total = sortedContacts.value.length
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

function openDetail(contact: ContactMessage) {
  selectedContact.value = contact
}

function closeDetail() {
  selectedContact.value = null
}

async function loadContacts() {
  loading.value = true
  errorMsg.value = ''
  try {
    contacts.value = await fetchContacts()
  } catch {
    errorMsg.value = 'データの取得に失敗しました。再度ログインしてください。'
    router.push('/lab/login')
  } finally {
    loading.value = false
  }
}

async function toggleReplied(contact: ContactMessage) {
  try {
    const updated = await updateContact(contact.id, !contact.is_replied)
    contact.is_replied = updated.is_replied
  } catch {
    errorMsg.value = 'ステータスの更新に失敗しました。'
  }
}

async function registerCustomer(contact: ContactMessage) {
  registering.value = true
  errorMsg.value = ''
  try {
    const customer = await createCustomer({
      name: contact.name,
      email: contact.email,
      phone: '',
      company: '',
      memo: `お問い合わせ「${contact.subject}」より登録`,
      source_contact: contact.id,
    })
    contact.customer_id = customer.id
  } catch {
    errorMsg.value = '顧客登録に失敗しました。'
  } finally {
    registering.value = false
  }
}

onMounted(loadContacts)
</script>
