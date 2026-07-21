<template>
  <div class="max-w-5xl mx-auto px-6 py-10">
    <div class="mb-6 flex items-center justify-between">
      <div>
        <h2 class="text-xl font-bold">顧客管理</h2>
        <p class="text-sm text-white/60 mt-1">お問い合わせから登録した顧客・手動登録した顧客を管理する</p>
      </div>
      <button
        v-if="canWrite('customers')"
        type="button"
        class="text-sm px-4 py-2 rounded-full bg-primary text-black font-medium hover:opacity-90 transition-opacity"
        @click="openCreateForm"
      >
        + 新規顧客
      </button>
    </div>

    <div v-if="errorMsg" class="mb-6 bg-red-500/10 border border-red-500/30 text-red-300 rounded-xl p-4 text-sm">
      {{ errorMsg }}
    </div>

    <div class="mb-4 flex flex-wrap items-center gap-3">
      <input
        v-model="searchQuery"
        type="text"
        placeholder="氏名・メール・会社名・電話番号で検索"
        class="flex-1 min-w-[200px] rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm focus:outline-none focus:border-primary/60"
      />
    </div>

    <div v-if="loading" class="text-center text-white/60 py-20 text-sm">読み込み中...</div>

    <div v-else-if="sortedCustomers.length === 0" class="text-center text-white/60 py-20 text-sm">
      該当する顧客はありません
    </div>

    <template v-else>
      <div class="overflow-x-auto rounded-2xl border border-white/10">
        <table class="w-full text-sm">
          <thead class="bg-white/5 text-white/70 text-xs">
            <tr>
              <th class="px-4 py-3 text-left font-medium cursor-pointer select-none" @click="sortBy('name')">
                氏名{{ sortIndicator('name') }}
              </th>
              <th class="px-4 py-3 text-left font-medium">メールアドレス</th>
              <th class="px-4 py-3 text-left font-medium">電話番号</th>
              <th class="px-4 py-3 text-left font-medium cursor-pointer select-none" @click="sortBy('company')">
                会社名{{ sortIndicator('company') }}
              </th>
              <th class="px-4 py-3 text-left font-medium">由来</th>
              <th class="px-4 py-3 text-left font-medium">ポータル</th>
              <th class="px-4 py-3 text-left font-medium cursor-pointer select-none" @click="sortBy('created_at')">
                登録日時{{ sortIndicator('created_at') }}
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-white/10">
            <tr
              v-for="customer in pagedCustomers"
              :key="customer.id"
              class="cursor-pointer hover:bg-white/5"
              @click="openEditForm(customer)"
            >
              <td class="px-4 py-3 max-w-[180px] truncate">{{ customer.name }}</td>
              <td class="px-4 py-3 text-white/80">
                <a
                  v-if="customer.email"
                  :href="`mailto:${customer.email}`"
                  class="text-primary hover:underline"
                  @click.stop
                >{{ customer.email }}</a>
                <span v-else class="text-white/40">-</span>
              </td>
              <td class="px-4 py-3 whitespace-nowrap text-white/80">{{ customer.phone || '-' }}</td>
              <td class="px-4 py-3 max-w-[180px] truncate">{{ customer.company || '-' }}</td>
              <td class="px-4 py-3">
                <span
                  class="text-xs px-3 py-1 rounded-full border"
                  :class="customer.source_contact
                    ? 'border-primary/40 text-primary bg-primary/10'
                    : 'border-white/20 text-white/70'"
                >
                  {{ customer.source_contact ? 'お問い合わせ経由' : '手動登録' }}
                </span>
              </td>
              <td class="px-4 py-3">
                <span
                  class="text-xs px-3 py-1 rounded-full border"
                  :class="customer.has_login
                    ? 'border-green-500/40 text-green-400 bg-green-500/10'
                    : 'border-white/20 text-white/50'"
                >
                  {{ customer.has_login ? '招待済み' : '未招待' }}
                </span>
              </td>
              <td class="px-4 py-3 whitespace-nowrap text-white/80">{{ formatDate(customer.created_at) }}</td>
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
          <h3 class="font-semibold text-base">{{ editingCustomer ? '顧客を編集' : '顧客を新規作成' }}</h3>
          <button type="button" class="text-white/60 hover:text-white transition-colors" @click="closeForm">✕</button>
        </div>

        <div>
          <label class="block text-xs text-white/60 mb-1">氏名</label>
          <input
            v-model="form.name"
            type="text"
            :disabled="!canWrite('customers')"
            class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2.5 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50"
          />
        </div>

        <div class="flex gap-4">
          <div class="flex-1">
            <label class="block text-xs text-white/60 mb-1">メールアドレス</label>
            <input
              v-model="form.email"
              type="email"
              :disabled="!canWrite('customers')"
              class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2.5 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50"
            />
          </div>
          <div class="flex-1">
            <label class="block text-xs text-white/60 mb-1">電話番号</label>
            <input
              v-model="form.phone"
              type="text"
              :disabled="!canWrite('customers')"
              class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2.5 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50"
            />
          </div>
        </div>

        <div>
          <label class="block text-xs text-white/60 mb-1">会社名</label>
          <input
            v-model="form.company"
            type="text"
            :disabled="!canWrite('customers')"
            class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2.5 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50"
          />
        </div>

        <div>
          <label class="block text-xs text-white/60 mb-1">メモ</label>
          <textarea
            v-model="form.memo"
            rows="6"
            :disabled="!canWrite('customers')"
            class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2.5 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50"
          />
        </div>

        <div v-if="editingCustomer && canWrite('customers')" class="flex items-center gap-2">
          <button
            v-if="!editingCustomer.has_login"
            type="button"
            class="text-xs px-3 py-1 rounded-full border border-primary/40 text-primary hover:bg-primary/10 transition-colors disabled:opacity-50"
            :disabled="inviting || !editingCustomer.email"
            @click="inviteToLab(editingCustomer)"
          >
            {{ inviting ? '招待中...' : '+ ポータルへ招待' }}
          </button>
          <template v-else>
            <span class="text-xs px-3 py-1 rounded-full border border-green-500/40 text-green-400 bg-green-500/10">
              ポータル招待済み
            </span>
            <button
              type="button"
              class="text-xs px-3 py-1 rounded-full border border-white/20 text-white/70 hover:bg-white/10 transition-colors disabled:opacity-50"
              :disabled="inviting || !editingCustomer.email"
              @click="inviteToLab(editingCustomer)"
            >
              {{ inviting ? '送信中...' : '招待メール再送' }}
            </button>
          </template>
        </div>
        <div
          v-else-if="editingCustomer?.has_login"
          class="text-xs px-3 py-1 rounded-full border border-green-500/40 text-green-400 bg-green-500/10 inline-block"
        >
          ポータル招待済み
        </div>

        <div class="flex items-center justify-between pt-2">
          <button
            v-if="editingCustomer && canWrite('customers')"
            type="button"
            class="text-xs text-red-400/70 hover:text-red-400 transition-colors"
            @click="removeCustomer(editingCustomer)"
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
              {{ canWrite('customers') ? 'キャンセル' : '閉じる' }}
            </button>
            <button
              v-if="canWrite('customers')"
              type="button"
              class="text-sm px-4 py-2 rounded-full bg-primary text-black font-medium hover:opacity-90 transition-opacity disabled:opacity-50"
              :disabled="!form.name || saving"
              @click="submitForm"
            >
              {{ editingCustomer ? '更新する' : '作成する' }}
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
  createCustomer,
  deleteCustomer,
  fetchCustomers,
  inviteCustomer,
  updateCustomer,
  type Customer,
  type CustomerInput,
} from '../../lib/api'
import { canWrite } from '../../lib/permissions'

type SortKey = 'name' | 'company' | 'created_at'

const customers = ref<Customer[]>([])
const loading = ref(true)
const saving = ref(false)
const errorMsg = ref('')
const showForm = ref(false)
const editingCustomer = ref<Customer | null>(null)
const inviting = ref(false)

const searchQuery = ref('')
const sortKey = ref<SortKey>('created_at')
const sortAsc = ref(false)
const page = ref(1)
const pageSize = 20

const form = reactive<CustomerInput>({
  name: '',
  email: '',
  phone: '',
  company: '',
  memo: '',
})

function formatDate(iso: string): string {
  return new Date(iso).toLocaleString('ja-JP', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  })
}

const filteredCustomers = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  if (!query) return customers.value
  return customers.value.filter((c) =>
    c.name.toLowerCase().includes(query) ||
    c.email.toLowerCase().includes(query) ||
    c.company.toLowerCase().includes(query) ||
    c.phone.toLowerCase().includes(query),
  )
})

const sortedCustomers = computed(() => {
  const list = [...filteredCustomers.value]
  list.sort((a, b) => {
    const av = a[sortKey.value] ?? ''
    const bv = b[sortKey.value] ?? ''
    if (av < bv) return sortAsc.value ? -1 : 1
    if (av > bv) return sortAsc.value ? 1 : -1
    return 0
  })
  return list
})

const totalPages = computed(() => Math.max(1, Math.ceil(sortedCustomers.value.length / pageSize)))

const pagedCustomers = computed(() => {
  const start = (page.value - 1) * pageSize
  return sortedCustomers.value.slice(start, start + pageSize)
})

const rangeLabel = computed(() => {
  const total = sortedCustomers.value.length
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

watch(searchQuery, () => {
  page.value = 1
})

watch(totalPages, (pages) => {
  if (page.value > pages) page.value = pages
})

async function loadCustomers() {
  loading.value = true
  errorMsg.value = ''
  try {
    customers.value = await fetchCustomers()
  } catch {
    errorMsg.value = '顧客一覧の取得に失敗しました。'
  } finally {
    loading.value = false
  }
}

function resetForm() {
  form.name = ''
  form.email = ''
  form.phone = ''
  form.company = ''
  form.memo = ''
}

function openCreateForm() {
  editingCustomer.value = null
  resetForm()
  showForm.value = true
}

function openEditForm(customer: Customer) {
  editingCustomer.value = customer
  form.name = customer.name
  form.email = customer.email
  form.phone = customer.phone
  form.company = customer.company
  form.memo = customer.memo
  showForm.value = true
}

function closeForm() {
  showForm.value = false
  editingCustomer.value = null
}

async function submitForm() {
  saving.value = true
  errorMsg.value = ''
  try {
    if (editingCustomer.value) {
      const updated = await updateCustomer(editingCustomer.value.id, { ...form })
      const idx = customers.value.findIndex((c) => c.id === updated.id)
      if (idx !== -1) customers.value[idx] = updated
    } else {
      const created = await createCustomer({ ...form })
      customers.value.unshift(created)
    }
    closeForm()
  } catch {
    errorMsg.value = '保存に失敗しました。'
  } finally {
    saving.value = false
  }
}

async function inviteToLab(customer: Customer) {
  inviting.value = true
  errorMsg.value = ''
  try {
    const wasInvited = customer.has_login
    const updated = await inviteCustomer(customer.id)
    const idx = customers.value.findIndex((c) => c.id === updated.id)
    if (idx !== -1) customers.value[idx] = updated
    editingCustomer.value = updated
    alert(wasInvited ? '招待メールを再送しました。' : '招待メールを送信しました。')
  } catch {
    errorMsg.value = 'ポータルへの招待に失敗しました。'
  } finally {
    inviting.value = false
  }
}

async function removeCustomer(customer: Customer) {
  if (!confirm(`「${customer.name}」を削除しますか？`)) return
  try {
    await deleteCustomer(customer.id)
    customers.value = customers.value.filter((c) => c.id !== customer.id)
    closeForm()
  } catch {
    errorMsg.value = '削除に失敗しました。'
  }
}

onMounted(loadCustomers)
</script>
