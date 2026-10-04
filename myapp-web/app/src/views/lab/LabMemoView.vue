<template>
  <div class="max-w-3xl mx-auto px-6 py-10">
    <div class="mb-8 flex items-center justify-between gap-4">
      <div>
        <h2 class="text-xl font-bold">メモ</h2>
        <p class="text-sm text-white/60 mt-1">日記とは別に、メモとして残す</p>
      </div>
      <button
        v-if="canWrite('memo')"
        type="button"
        class="shrink-0 text-sm px-4 py-2 rounded-full bg-primary text-black font-medium hover:opacity-90"
        @click="startNew"
      >
        メモを追加
      </button>
    </div>

    <div v-if="errorMsg" class="mb-6 bg-red-500/10 border border-red-500/30 text-red-300 rounded-xl p-4 text-sm">
      {{ errorMsg }}
    </div>

    <div v-if="loading" class="text-center text-white/60 py-10 text-sm">読み込み中...</div>

    <p v-else-if="memos.length === 0" class="text-sm text-white/50">メモはまだありません。</p>

    <div v-else class="space-y-3">
      <button
        v-for="memo in memos"
        :key="memo.id"
        type="button"
        class="flex w-full items-start gap-4 rounded-2xl border border-white/10 p-4 text-left hover:border-white/30"
        @click="startEdit(memo)"
      >
        <span class="w-16 shrink-0 text-xs font-medium text-indigo-300">{{ memoLabel(memo) }}</span>
        <img
          v-if="memo.photos?.length"
          :src="memo.photos[0].url"
          alt=""
          class="h-14 w-14 shrink-0 rounded-lg object-cover"
        />
        <span class="min-w-0">
          <span class="block truncate text-sm font-medium">{{ memo.title || '無題' }}</span>
          <span class="mt-1 block line-clamp-2 text-xs text-white/60 whitespace-pre-wrap">{{ memo.content || '本文なし' }}</span>
        </span>
      </button>
    </div>

    <div
      v-if="showDialog"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4"
      @click.self="closeDialog"
    >
      <div
        class="w-full max-w-lg max-h-[90vh] overflow-y-auto rounded-2xl border border-white/10 bg-[#0c1220] p-8 space-y-4"
        @paste="onPaste"
      >
        <div class="flex items-center justify-between">
          <h3 class="font-semibold text-base">{{ editing ? 'メモを編集' : 'メモを追加' }}</h3>
          <button type="button" class="text-white/60 hover:text-white" @click="closeDialog">✕</button>
        </div>
        <label class="block text-xs text-white/60">
          日付
          <input
            v-model="form.date"
            type="date"
            class="mt-1 w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2.5 text-sm focus:outline-none focus:border-primary/60"
          />
        </label>
        <input
          v-model="form.title"
          type="text"
          placeholder="タイトル"
          class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2.5 text-sm focus:outline-none focus:border-primary/60"
        />
        <textarea
          v-model="form.content"
          rows="6"
          placeholder="本文。画像はここに貼り付けられます"
          class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2.5 text-sm focus:outline-none focus:border-primary/60"
        />
        <div>
          <label class="block text-xs text-white/60 mb-2">写真</label>
          <div class="flex flex-wrap gap-2 mb-3">
            <button
              v-for="photo in keptPhotos"
              :key="photo.id"
              type="button"
              class="relative h-20 w-20"
              @click="removedPhotoIds.push(photo.id)"
            >
              <img :src="photo.url" alt="" class="h-20 w-20 rounded-lg object-cover border border-white/10" />
              <span class="absolute top-0.5 right-0.5 text-[10px] bg-black/70 rounded px-1">削除</span>
            </button>
            <button
              v-for="(file, index) in pendingFiles"
              :key="file.name + index"
              type="button"
              class="relative h-20 w-20"
              @click="removePending(index)"
            >
              <img :src="pendingUrls[index]" alt="" class="h-20 w-20 rounded-lg object-cover border border-white/10" />
              <span class="absolute top-0.5 right-0.5 text-[10px] bg-black/70 rounded px-1">取消</span>
            </button>
          </div>
          <div class="flex flex-wrap gap-2">
            <button type="button" class="text-xs px-3 py-1.5 rounded-full border border-white/20 hover:border-white/40" @click="fileInput?.click()">
              ファイルを選択
            </button>
            <button type="button" class="text-xs px-3 py-1.5 rounded-full border border-white/20 hover:border-white/40" @click="cameraInput?.click()">
              カメラ
            </button>
          </div>
          <input ref="cameraInput" type="file" accept="image/*" capture="environment" class="hidden" @change="onPickPhotos" />
          <input ref="fileInput" type="file" accept="image/*" multiple class="hidden" @change="onPickPhotos" />
        </div>
        <div class="flex items-center justify-between pt-2">
          <button
            v-if="editing"
            type="button"
            class="text-xs text-red-400/70 hover:text-red-400"
            @click="removeMemo(editing)"
          >
            削除
          </button>
          <span v-else />
          <div class="flex gap-2">
            <button type="button" class="text-xs text-white/60 hover:text-white" @click="closeDialog">キャンセル</button>
            <button
              type="button"
              class="text-sm px-4 py-2 rounded-full bg-primary text-black font-medium disabled:opacity-50"
              :disabled="saving || (!form.title && !form.content && !keptPhotos.length && !pendingFiles.length)"
              @click="save"
            >
              {{ editing ? '更新する' : 'メモとして保存' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import {
  createMemo,
  deleteMemo,
  deleteMemoPhoto,
  fetchMemos,
  updateMemo,
  uploadMemoPhoto,
  type DiaryPhoto,
  type Memo,
} from '../../lib/api'
import { canWrite } from '../../lib/permissions'

const memos = ref<Memo[]>([])
const loading = ref(true)
const saving = ref(false)
const errorMsg = ref('')
const showDialog = ref(false)
const editing = ref<Memo | null>(null)
const form = reactive({ date: '', title: '', content: '' })
const cameraInput = ref<HTMLInputElement | null>(null)
const fileInput = ref<HTMLInputElement | null>(null)
const pendingFiles = ref<File[]>([])
const pendingUrls = ref<string[]>([])
const removedPhotoIds = ref<number[]>([])

const keptPhotos = computed<DiaryPhoto[]>(() =>
  (editing.value?.photos ?? []).filter((photo) => !removedPhotoIds.value.includes(photo.id)),
)

function todayIso(): string {
  const now = new Date()
  const m = String(now.getMonth() + 1).padStart(2, '0')
  const d = String(now.getDate()).padStart(2, '0')
  return `${now.getFullYear()}-${m}-${d}`
}

function memoDay(memo: Memo): string {
  return memo.date || memo.created_at.slice(0, 10)
}

function memoLabel(memo: Memo): string {
  const [year, month, day] = memoDay(memo).split('-')
  return `${year}/${month}/${day}`
}

function clearPending() {
  pendingUrls.value.forEach((url) => URL.revokeObjectURL(url))
  pendingFiles.value = []
  pendingUrls.value = []
}

function startNew() {
  editing.value = null
  form.date = todayIso()
  form.title = ''
  form.content = ''
  removedPhotoIds.value = []
  clearPending()
  showDialog.value = true
}

function startEdit(memo: Memo) {
  editing.value = memo
  form.date = memoDay(memo)
  form.title = memo.title
  form.content = memo.content
  removedPhotoIds.value = []
  clearPending()
  showDialog.value = true
}

function closeDialog() {
  showDialog.value = false
  clearPending()
}

function removePending(index: number) {
  URL.revokeObjectURL(pendingUrls.value[index])
  pendingFiles.value.splice(index, 1)
  pendingUrls.value.splice(index, 1)
}

async function compressImage(file: File): Promise<File> {
  try {
    const bitmap = await createImageBitmap(file)
    const maxEdge = 1600
    const scale = Math.min(1, maxEdge / Math.max(bitmap.width, bitmap.height))
    const width = Math.max(1, Math.round(bitmap.width * scale))
    const height = Math.max(1, Math.round(bitmap.height * scale))
    const canvas = document.createElement('canvas')
    canvas.width = width
    canvas.height = height
    const ctx = canvas.getContext('2d')
    if (!ctx) return file
    ctx.drawImage(bitmap, 0, 0, width, height)
    bitmap.close()
    const blob = await new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, 'image/jpeg', 0.72))
    if (!blob) return file
    const name = file.name.replace(/\.[^.]+$/, '') || 'photo'
    return new File([blob], `${name}.jpg`, { type: 'image/jpeg' })
  } catch {
    return file
  }
}

async function addFiles(files: File[]) {
  for (const file of files) {
    const compressed = await compressImage(file)
    pendingFiles.value.push(compressed)
    pendingUrls.value.push(URL.createObjectURL(compressed))
  }
}

async function onPickPhotos(event: Event) {
  const input = event.target as HTMLInputElement
  const files = Array.from(input.files ?? [])
  input.value = ''
  await addFiles(files)
}

async function onPaste(event: ClipboardEvent) {
  const items = event.clipboardData?.items
  if (!items) return
  const files: File[] = []
  for (const item of items) {
    if (!item.type.startsWith('image/')) continue
    const file = item.getAsFile()
    if (file) files.push(file)
  }
  if (!files.length) return
  event.preventDefault()
  await addFiles(files)
}

async function load() {
  loading.value = true
  errorMsg.value = ''
  try {
    const data = await fetchMemos()
    memos.value = [...data].sort((a, b) => memoDay(b).localeCompare(memoDay(a)) || b.id - a.id)
  } catch {
    errorMsg.value = 'メモの取得に失敗しました。'
  } finally {
    loading.value = false
  }
}

async function save() {
  saving.value = true
  errorMsg.value = ''
  try {
    const input = { date: form.date || null, title: form.title, content: form.content }
    const saved = editing.value ? await updateMemo(editing.value.id, input) : await createMemo(input)
    for (const photoId of removedPhotoIds.value) {
      await deleteMemoPhoto(saved.id, photoId)
    }
    for (const file of pendingFiles.value) {
      await uploadMemoPhoto(saved.id, file)
    }
    await load()
    closeDialog()
  } catch {
    errorMsg.value = 'メモの保存に失敗しました。'
  } finally {
    saving.value = false
  }
}

async function removeMemo(memo: Memo) {
  if (!confirm(`「${memo.title || '無題'}」を削除しますか？`)) return
  try {
    await deleteMemo(memo.id)
    await load()
    closeDialog()
  } catch {
    errorMsg.value = 'メモの削除に失敗しました。'
  }
}

onMounted(load)
</script>
