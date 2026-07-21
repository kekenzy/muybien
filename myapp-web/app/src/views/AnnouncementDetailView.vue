<template>
  <section class="py-24 px-6">
    <div class="max-w-2xl mx-auto">
      <div v-if="loading" class="text-center text-gray-400 py-20 text-sm">読み込み中...</div>
      <div v-else-if="!announcement" class="text-center text-gray-400 py-20 text-sm">お知らせが見つかりません</div>
      <template v-else>
        <router-link to="/" class="text-xs text-primary hover:underline">← トップへ戻る</router-link>
        <div class="mt-6 mb-2 text-xs text-gray-400">{{ formatDate(announcement.published_at) }}</div>
        <h1 class="text-2xl sm:text-3xl font-bold text-gray-900 mb-8">{{ announcement.title }}</h1>
        <img
          v-if="announcement.cover_image"
          :src="announcement.cover_image"
          :alt="announcement.title"
          class="w-full rounded-2xl mb-8 object-cover"
        />
        <p class="text-gray-600 leading-relaxed whitespace-pre-line">{{ announcement.body }}</p>
      </template>
    </div>
  </section>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import { fetchPublicAnnouncement, type Announcement } from '../lib/api'

const route = useRoute()
const announcement = ref<Announcement | null>(null)
const loading = ref(true)

async function load() {
  loading.value = true
  try {
    announcement.value = await fetchPublicAnnouncement(Number(route.params.id))
  } catch {
    announcement.value = null
  } finally {
    loading.value = false
  }
}

function formatDate(iso: string | null): string {
  if (!iso) return ''
  return new Date(iso).toLocaleDateString('ja-JP', { year: 'numeric', month: '2-digit', day: '2-digit' })
}

onMounted(load)
</script>
