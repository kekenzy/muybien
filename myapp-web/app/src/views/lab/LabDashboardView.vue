<template>
  <div class="max-w-4xl mx-auto px-6 py-10">
    <div class="mb-8">
      <h2 class="text-xl font-bold">お問い合わせ一覧</h2>
      <p class="text-sm text-white/40 mt-1">コンタクトフォームから届いたメッセージ</p>
    </div>

    <div v-if="loading" class="text-center text-white/40 py-20 text-sm">読み込み中...</div>

    <div v-else-if="errorMsg" class="bg-red-500/10 border border-red-500/30 text-red-300 rounded-xl p-4 text-sm">
      {{ errorMsg }}
    </div>

    <div v-else-if="contacts.length === 0" class="text-center text-white/40 py-20 text-sm">
      お問い合わせはまだありません
    </div>

    <div v-else class="space-y-4">
      <article
        v-for="contact in contacts"
        :key="contact.id"
        class="rounded-2xl border border-white/10 bg-white/5 p-6"
      >
        <div class="flex flex-wrap items-start justify-between gap-3 mb-4">
          <div>
            <div class="font-semibold">{{ contact.name }}</div>
            <a :href="`mailto:${contact.email}`" class="text-sm text-primary hover:underline">{{ contact.email }}</a>
          </div>
          <div class="flex items-center gap-3">
            <time class="text-xs text-white/40">{{ formatDate(contact.created_at) }}</time>
            <button
              type="button"
              class="text-xs px-3 py-1 rounded-full border transition-colors"
              :class="contact.is_replied
                ? 'border-green-500/40 text-green-400 bg-green-500/10'
                : 'border-white/20 text-white/50 hover:border-white/40'"
              @click="toggleReplied(contact)"
            >
              {{ contact.is_replied ? '返信済み' : '未返信' }}
            </button>
          </div>
        </div>
        <div class="text-sm font-medium text-white/80 mb-2">{{ contact.subject }}</div>
        <p class="text-sm text-white/60 leading-relaxed whitespace-pre-wrap">{{ contact.message }}</p>
      </article>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { fetchContacts, updateContact, type ContactMessage } from '../../lib/api'

const router = useRouter()
const contacts = ref<ContactMessage[]>([])
const loading = ref(true)
const errorMsg = ref('')

function formatDate(iso: string): string {
  return new Date(iso).toLocaleString('ja-JP', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  })
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

onMounted(loadContacts)
</script>
