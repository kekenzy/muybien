<template>
  <div class="max-w-5xl mx-auto px-6 py-10">
    <div class="mb-6">
      <h2 class="text-xl font-bold">サイトコンテンツ管理</h2>
      <p class="text-sm text-white/60 mt-1">公開サイトの見出し・CTA文言やホーム/サービス/実績/プロフィールの各リスト項目を編集する</p>
    </div>

    <div v-if="errorMsg" class="mb-6 bg-red-500/10 border border-red-500/30 text-red-300 rounded-xl p-4 text-sm">
      {{ errorMsg }}
    </div>

    <div class="mb-6 flex gap-2 border-b border-white/10">
      <button
        type="button"
        class="px-4 py-2 text-sm border-b-2 transition-colors"
        :class="tab === 'texts' ? 'border-primary text-white' : 'border-transparent text-white/50 hover:text-white'"
        @click="tab = 'texts'"
      >
        テキスト
      </button>
      <button
        type="button"
        class="px-4 py-2 text-sm border-b-2 transition-colors"
        :class="tab === 'items' ? 'border-primary text-white' : 'border-transparent text-white/50 hover:text-white'"
        @click="tab = 'items'"
      >
        リスト項目
      </button>
    </div>

    <!-- テキストタブ -->
    <div v-if="tab === 'texts'">
      <div v-if="loadingTexts" class="text-center text-white/60 py-20 text-sm">読み込み中...</div>
      <div v-else class="space-y-4">
        <div
          v-for="text in siteTexts"
          :key="text.key"
          class="rounded-2xl border border-white/10 p-5"
        >
          <div class="flex items-center justify-between mb-2">
            <label class="text-xs font-mono text-white/50">{{ text.key }}</label>
            <button
              v-if="canWrite('site_content')"
              type="button"
              class="text-xs px-3 py-1 rounded-full bg-primary text-black font-medium hover:opacity-90 transition-opacity disabled:opacity-50"
              :disabled="savingTextKey === text.key"
              @click="saveText(text)"
            >
              {{ savingTextKey === text.key ? '保存中...' : '保存' }}
            </button>
          </div>
          <textarea
            v-model="text.value"
            rows="2"
            :disabled="!canWrite('site_content')"
            class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2.5 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50"
          />
        </div>
      </div>
    </div>

    <!-- リスト項目タブ -->
    <div v-else>
      <div class="mb-5 flex items-center justify-between gap-3">
        <select
          v-model="selectedSection"
          class="rounded-lg bg-white/5 border border-white/10 px-3 py-2.5 text-sm focus:outline-none focus:border-primary/60"
        >
          <option v-for="opt in CONTENT_SECTION_OPTIONS" :key="opt.key" :value="opt.key">{{ opt.label }}</option>
        </select>
        <button
          v-if="canWrite('site_content')"
          type="button"
          class="text-sm px-4 py-2 rounded-full bg-primary text-black font-medium hover:opacity-90 transition-opacity"
          @click="addItem"
        >
          + 新規項目
        </button>
      </div>

      <div v-if="loadingItems" class="text-center text-white/60 py-20 text-sm">読み込み中...</div>
      <div v-else-if="items.length === 0" class="text-center text-white/60 py-20 text-sm">項目がありません</div>

      <div v-else class="space-y-4">
        <div
          v-for="item in items"
          :key="item.id ?? item._tempId"
          class="rounded-2xl border border-white/10 p-5 space-y-4"
        >
          <div class="flex flex-wrap items-center gap-4">
            <div>
              <label class="block text-xs text-white/60 mb-1">表示順</label>
              <input
                v-model.number="item.order"
                type="number"
                :disabled="!canWrite('site_content')"
                class="w-24 rounded-lg bg-white/5 border border-white/10 px-3 py-2 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50"
              />
            </div>
            <label class="flex items-center gap-2 text-sm text-white/80 mt-4">
              <input v-model="item.is_active" type="checkbox" :disabled="!canWrite('site_content')" class="rounded" />
              表示する
            </label>
          </div>

          <div class="grid sm:grid-cols-2 gap-4">
            <div>
              <label class="block text-xs text-white/60 mb-1">画像</label>
              <img
                v-if="item.image"
                :src="item.image"
                alt="画像"
                class="mb-2 h-16 w-auto rounded-lg border border-white/10 object-cover"
              />
              <input
                type="file"
                accept="image/*"
                :disabled="!canWrite('site_content')"
                class="w-full text-xs text-white/70 disabled:opacity-50"
                @change="(e) => onImageChange(item, 'image', e)"
              />
            </div>
            <div>
              <label class="block text-xs text-white/60 mb-1">画像2（任意）</label>
              <img
                v-if="item.image_secondary"
                :src="item.image_secondary"
                alt="画像2"
                class="mb-2 h-16 w-auto rounded-lg border border-white/10 object-cover"
              />
              <input
                type="file"
                accept="image/*"
                :disabled="!canWrite('site_content')"
                class="w-full text-xs text-white/70 disabled:opacity-50"
                @change="(e) => onImageChange(item, 'image_secondary', e)"
              />
            </div>
          </div>

          <div>
            <label class="block text-xs text-white/60 mb-1">データ（JSON形式）</label>
            <textarea
              v-model="item._dataText"
              rows="6"
              :disabled="!canWrite('site_content')"
              class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2.5 text-sm font-mono focus:outline-none focus:border-primary/60 disabled:opacity-50"
            />
          </div>

          <div v-if="canWrite('site_content')" class="flex items-center justify-between pt-1">
            <button
              type="button"
              class="text-xs text-red-400/70 hover:text-red-400 transition-colors"
              @click="removeItem(item)"
            >
              削除
            </button>
            <button
              type="button"
              class="text-sm px-4 py-2 rounded-full bg-primary text-black font-medium hover:opacity-90 transition-opacity disabled:opacity-50"
              :disabled="savingItemId === (item.id ?? item._tempId)"
              @click="saveItem(item)"
            >
              {{ savingItemId === (item.id ?? item._tempId) ? '保存中...' : '保存' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, watch } from 'vue'
import {
  CONTENT_SECTION_OPTIONS,
  createContentItem,
  deleteContentItem,
  fetchContentItems,
  fetchSiteTexts,
  updateContentItem,
  updateSiteText,
  type ContentItem,
  type ContentSection,
  type SiteText,
} from '../../lib/api'
import { canWrite } from '../../lib/permissions'

interface EditableItem extends Partial<ContentItem> {
  _tempId?: string
  _dataText: string
  _newImage?: File
  _newImageSecondary?: File
}

const tab = ref<'texts' | 'items'>('texts')
const errorMsg = ref('')

const siteTexts = ref<SiteText[]>([])
const loadingTexts = ref(true)
const savingTextKey = ref<string | null>(null)

const selectedSection = ref<ContentSection>(CONTENT_SECTION_OPTIONS[0].key)
const items = ref<EditableItem[]>([])
const loadingItems = ref(true)
const savingItemId = ref<number | string | null>(null)

async function loadTexts() {
  loadingTexts.value = true
  errorMsg.value = ''
  try {
    siteTexts.value = await fetchSiteTexts()
  } catch {
    errorMsg.value = 'テキスト一覧の取得に失敗しました。'
  } finally {
    loadingTexts.value = false
  }
}

async function saveText(text: SiteText) {
  savingTextKey.value = text.key
  errorMsg.value = ''
  try {
    await updateSiteText(text.key, text.value)
  } catch {
    errorMsg.value = '保存に失敗しました。'
  } finally {
    savingTextKey.value = null
  }
}

async function loadItems() {
  loadingItems.value = true
  errorMsg.value = ''
  try {
    const fetched = await fetchContentItems(selectedSection.value)
    items.value = fetched.map((item) => ({ ...item, _dataText: JSON.stringify(item.data, null, 2) }))
  } catch {
    errorMsg.value = '項目一覧の取得に失敗しました。'
  } finally {
    loadingItems.value = false
  }
}

function addItem() {
  items.value.push({
    _tempId: `new-${Date.now()}-${Math.random()}`,
    section: selectedSection.value,
    order: items.value.length,
    is_active: true,
    image: null,
    image_secondary: null,
    _dataText: '{}',
  })
}

function onImageChange(item: EditableItem, field: 'image' | 'image_secondary', event: Event) {
  const file = (event.target as HTMLInputElement).files?.[0]
  if (field === 'image') item._newImage = file
  else item._newImageSecondary = file
}

async function saveItem(item: EditableItem) {
  let data: Record<string, any>
  try {
    data = JSON.parse(item._dataText || '{}')
  } catch {
    errorMsg.value = 'データのJSON形式が正しくありません。'
    return
  }

  savingItemId.value = item.id ?? item._tempId ?? null
  errorMsg.value = ''
  try {
    const input = {
      section: selectedSection.value,
      order: item.order ?? 0,
      is_active: item.is_active ?? true,
      data,
      image: item._newImage,
      image_secondary: item._newImageSecondary,
    }
    if (item.id) {
      const updated = await updateContentItem(item.id, input)
      Object.assign(item, updated, { _dataText: JSON.stringify(updated.data, null, 2) })
    } else {
      const created = await createContentItem(input)
      Object.assign(item, created, { _dataText: JSON.stringify(created.data, null, 2), _tempId: undefined })
    }
  } catch {
    errorMsg.value = '保存に失敗しました。'
  } finally {
    savingItemId.value = null
  }
}

async function removeItem(item: EditableItem) {
  if (!item.id) {
    items.value = items.value.filter((i) => i !== item)
    return
  }
  if (!confirm('この項目を削除しますか？')) return
  try {
    await deleteContentItem(item.id)
    items.value = items.value.filter((i) => i.id !== item.id)
  } catch {
    errorMsg.value = '削除に失敗しました。'
  }
}

watch(selectedSection, loadItems)

onMounted(() => {
  loadTexts()
  loadItems()
})
</script>
