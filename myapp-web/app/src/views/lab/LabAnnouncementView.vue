<template>
  <div class="max-w-5xl mx-auto px-6 py-10">
    <div class="mb-6 flex items-center justify-between">
      <div>
        <h2 class="text-xl font-bold">お知らせ管理</h2>
        <p class="text-sm text-white/60 mt-1">公開サイトのトップページに表示するお知らせを管理する</p>
      </div>
      <button
        v-if="canWrite('announcements')"
        type="button"
        class="text-sm px-4 py-2 rounded-full bg-primary text-black font-medium hover:opacity-90 transition-opacity"
        @click="openCreateForm"
      >
        + 新規作成
      </button>
    </div>

    <div v-if="errorMsg" class="mb-6 bg-red-500/10 border border-red-500/30 text-red-300 rounded-xl p-4 text-sm">
      {{ errorMsg }}
    </div>

    <div v-if="loading" class="text-center text-white/60 py-20 text-sm">読み込み中...</div>

    <div v-else-if="announcements.length === 0" class="text-center text-white/60 py-20 text-sm">
      お知らせはまだありません
    </div>

    <div v-else class="overflow-x-auto rounded-2xl border border-white/10">
      <table class="w-full text-sm">
        <thead class="bg-white/5 text-white/70 text-xs">
          <tr>
            <th class="px-4 py-3 text-left font-medium">タイトル</th>
            <th class="px-4 py-3 text-left font-medium">状態</th>
            <th class="px-4 py-3 text-left font-medium">公開日時</th>
            <th class="px-4 py-3 text-left font-medium">更新日時</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-white/10">
          <tr
            v-for="item in announcements"
            :key="item.id"
            class="cursor-pointer hover:bg-white/5"
            @click="openEditForm(item)"
          >
            <td class="px-4 py-3 max-w-[280px] truncate">{{ item.title }}</td>
            <td class="px-4 py-3">
              <span
                class="text-xs px-3 py-1 rounded-full border"
                :class="item.is_published
                  ? 'border-green-500/40 text-green-400 bg-green-500/10'
                  : 'border-white/20 text-white/60'"
              >
                {{ item.is_published ? '公開中' : '下書き' }}
              </span>
            </td>
            <td class="px-4 py-3 whitespace-nowrap text-white/80">{{ formatDate(item.published_at) }}</td>
            <td class="px-4 py-3 whitespace-nowrap text-white/80">{{ formatDate(item.updated_at) }}</td>
          </tr>
        </tbody>
      </table>
    </div>

    <div
      v-if="showForm"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4"
      @click.self="closeForm"
    >
      <div class="w-full max-w-2xl max-h-[90vh] overflow-y-auto rounded-2xl border border-white/10 bg-[#0c1220] p-8 space-y-5">
        <div class="flex items-center justify-between">
          <h3 class="font-semibold text-base">{{ editingItem ? 'お知らせを編集' : 'お知らせを新規作成' }}</h3>
          <button type="button" class="text-white/60 hover:text-white transition-colors" @click="closeForm">✕</button>
        </div>

        <div>
          <label class="block text-xs text-white/60 mb-1">タイトル</label>
          <input
            v-model="form.title"
            type="text"
            :disabled="!canWrite('announcements')"
            class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2.5 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50"
          />
        </div>

        <div>
          <label class="block text-xs text-white/60 mb-1">本文</label>
          <textarea
            v-model="form.body"
            rows="8"
            :disabled="!canWrite('announcements')"
            class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2.5 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50"
          />
        </div>

        <div>
          <label class="block text-xs text-white/60 mb-1">アイキャッチ画像</label>
          <img
            v-if="editingItem?.cover_image"
            :src="editingItem.cover_image"
            alt="現在の画像"
            class="mb-2 h-24 w-auto rounded-lg border border-white/10 object-cover"
          />
          <input
            type="file"
            accept="image/*"
            :disabled="!canWrite('announcements')"
            class="w-full text-sm text-white/70 disabled:opacity-50"
            @change="onCoverImageChange"
          />
        </div>

        <div class="flex gap-4">
          <div class="flex-1">
            <label class="block text-xs text-white/60 mb-1">公開日時</label>
            <input
              v-model="form.published_at"
              type="datetime-local"
              :disabled="!canWrite('announcements')"
              class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2.5 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50"
            />
          </div>
          <div class="flex items-end pb-2.5">
            <label class="flex items-center gap-2 text-sm text-white/80">
              <input
                v-model="form.is_published"
                type="checkbox"
                :disabled="!canWrite('announcements')"
                class="rounded"
              />
              公開する
            </label>
          </div>
        </div>

        <div class="flex items-center justify-between pt-2">
          <button
            v-if="editingItem && canWrite('announcements')"
            type="button"
            class="text-xs text-red-400/70 hover:text-red-400 transition-colors"
            @click="removeAnnouncement(editingItem)"
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
              {{ canWrite('announcements') ? 'キャンセル' : '閉じる' }}
            </button>
            <button
              v-if="canWrite('announcements')"
              type="button"
              class="text-sm px-4 py-2 rounded-full bg-primary text-black font-medium hover:opacity-90 transition-opacity disabled:opacity-50"
              :disabled="!form.title || saving"
              @click="submitForm"
            >
              {{ editingItem ? '更新する' : '作成する' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import {
  createAnnouncement,
  deleteAnnouncement,
  fetchAnnouncements,
  updateAnnouncement,
  type Announcement,
} from '../../lib/api'
import { canWrite } from '../../lib/permissions'

const announcements = ref<Announcement[]>([])
const loading = ref(true)
const saving = ref(false)
const errorMsg = ref('')
const showForm = ref(false)
const editingItem = ref<Announcement | null>(null)

const form = reactive({
  title: '',
  body: '',
  is_published: false,
  published_at: '' as string,
  cover_image: undefined as File | undefined,
})

function formatDate(iso: string | null): string {
  if (!iso) return '-'
  return new Date(iso).toLocaleString('ja-JP', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  })
}

// datetime-local <-> ISO文字列の相互変換
function toLocalInput(iso: string | null): string {
  if (!iso) return ''
  const date = new Date(iso)
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`
}

async function loadAnnouncements() {
  loading.value = true
  errorMsg.value = ''
  try {
    announcements.value = await fetchAnnouncements()
  } catch {
    errorMsg.value = 'お知らせ一覧の取得に失敗しました。'
  } finally {
    loading.value = false
  }
}

function resetForm() {
  form.title = ''
  form.body = ''
  form.is_published = false
  form.published_at = ''
  form.cover_image = undefined
}

function openCreateForm() {
  editingItem.value = null
  resetForm()
  showForm.value = true
}

function openEditForm(item: Announcement) {
  editingItem.value = item
  form.title = item.title
  form.body = item.body
  form.is_published = item.is_published
  form.published_at = toLocalInput(item.published_at)
  form.cover_image = undefined
  showForm.value = true
}

function closeForm() {
  showForm.value = false
  editingItem.value = null
}

function onCoverImageChange(event: Event) {
  const file = (event.target as HTMLInputElement).files?.[0]
  form.cover_image = file ?? undefined
}

async function submitForm() {
  saving.value = true
  errorMsg.value = ''
  try {
    const input = {
      title: form.title,
      body: form.body,
      is_published: form.is_published,
      published_at: form.published_at ? new Date(form.published_at).toISOString() : null,
      cover_image: form.cover_image,
    }
    if (editingItem.value) {
      const updated = await updateAnnouncement(editingItem.value.id, input)
      const idx = announcements.value.findIndex((a) => a.id === updated.id)
      if (idx !== -1) announcements.value[idx] = updated
    } else {
      const created = await createAnnouncement(input)
      announcements.value.unshift(created)
    }
    closeForm()
  } catch {
    errorMsg.value = '保存に失敗しました。'
  } finally {
    saving.value = false
  }
}

async function removeAnnouncement(item: Announcement) {
  if (!confirm(`「${item.title}」を削除しますか？`)) return
  try {
    await deleteAnnouncement(item.id)
    announcements.value = announcements.value.filter((a) => a.id !== item.id)
    closeForm()
  } catch {
    errorMsg.value = '削除に失敗しました。'
  }
}

onMounted(loadAnnouncements)
</script>
