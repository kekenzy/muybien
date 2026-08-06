<template>
  <div>
    <!-- Hero -->
    <section class="relative py-20 sm:py-32 px-4 sm:px-6 bg-[#080c14] overflow-hidden">
      <div class="absolute inset-0 bg-[linear-gradient(to_right,#ffffff08_1px,transparent_1px),linear-gradient(to_bottom,#ffffff08_1px,transparent_1px)] bg-[size:48px_48px]" />
      <div class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[500px] h-[500px] bg-blue-600/15 rounded-full blur-[120px] pointer-events-none" />

      <div class="relative max-w-4xl mx-auto">
        <span class="text-xs font-semibold tracking-widest text-primary uppercase">Profile</span>
        <h1 class="text-4xl sm:text-5xl md:text-7xl font-black text-white mt-4 mb-6 leading-tight">
          {{ texts.profile_name || '永井 謙史' }}
        </h1>
        <p class="text-white/50 text-base sm:text-lg md:text-xl max-w-xl leading-relaxed whitespace-pre-line">
          {{ texts.profile_tagline }}
        </p>
        <a
          :href="texts.profile_blog_url || 'https://kenzy-goldentime.blogspot.com/'"
          target="_blank"
          rel="noopener noreferrer"
          class="inline-flex items-center gap-2 mt-8 text-sm text-white/50 hover:text-white transition-colors"
        >
          📝 Fly Away（ブログ） →
        </a>
      </div>
    </section>

    <!-- About -->
    <section class="py-24 px-6 bg-white">
      <div class="max-w-4xl mx-auto">
        <div class="text-center mb-16">
          <span class="text-xs font-semibold tracking-widest text-primary uppercase">About</span>
          <h2 class="text-3xl font-bold mt-2 text-gray-900">{{ texts.profile_about_heading || 'こんな人です' }}</h2>
        </div>

        <div class="grid md:grid-cols-3 gap-6">
          <div
            v-for="item in values"
            :key="item.title"
            class="p-8 rounded-2xl border border-gray-100 hover:border-primary/30 hover:shadow-md transition-all"
          >
            <div class="text-3xl mb-4">{{ item.emoji }}</div>
            <div class="font-semibold text-gray-900 mb-2">{{ item.title }}</div>
            <div class="text-sm text-gray-500 leading-relaxed">{{ item.desc }}</div>
          </div>
        </div>
      </div>
    </section>

    <!-- Career -->
    <section class="py-24 px-6 bg-gray-50">
      <div class="max-w-3xl mx-auto">
        <div class="text-center mb-16">
          <span class="text-xs font-semibold tracking-widest text-primary uppercase">Career</span>
          <h2 class="text-3xl font-bold mt-2 text-gray-900">{{ texts.profile_career_heading || 'キャリア' }}</h2>
        </div>

        <div class="relative pl-6 sm:pl-8 border-l-2 border-gray-200 space-y-10 sm:space-y-12">
          <div v-for="item in career" :key="item.year" class="relative">
            <div class="absolute -left-[1.65rem] sm:-left-[2.35rem] w-3.5 h-3.5 sm:w-4 sm:h-4 bg-primary rounded-full border-4 border-white shadow" />
            <div class="text-xs font-semibold text-primary mb-1">{{ item.year }}</div>
            <div class="font-bold text-gray-900 text-lg mb-1">{{ item.company }}</div>
            <div class="text-sm text-gray-500 leading-relaxed mb-4">{{ item.desc }}</div>
            <div class="flex flex-wrap gap-2">
              <span
                v-for="proj in item.projects"
                :key="proj"
                class="text-xs px-3 py-1 rounded-full bg-white border border-gray-200 text-gray-600"
              >{{ proj }}</span>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Apps -->
    <section class="py-24 px-6 bg-white">
      <div class="max-w-4xl mx-auto">
        <div class="text-center mb-16">
          <span class="text-xs font-semibold tracking-widest text-primary uppercase">Apps</span>
          <h2 class="text-3xl font-bold mt-2 text-gray-900">{{ texts.profile_apps_heading || '作成物' }}</h2>
        </div>

        <div class="grid md:grid-cols-2 gap-6">
          <div
            v-for="app in apps"
            :key="app.title"
            class="flex flex-col p-8 rounded-2xl border border-gray-100 hover:border-primary/30 hover:shadow-md transition-all"
          >
            <div class="flex items-center justify-between mb-4">
              <span class="text-xs font-semibold text-primary bg-blue-50 px-3 py-1 rounded-full">{{ app.category }}</span>
              <span class="text-xs text-gray-400">{{ app.date }}</span>
            </div>
            <div class="mb-2">
              <img
                v-if="app.icon"
                :src="app.icon"
                :alt="app.title"
                class="h-12 w-auto object-contain rounded-xl"
              />
              <span v-else class="text-2xl">{{ app.emoji }}</span>
            </div>
            <h3 class="font-semibold text-lg text-gray-900 mb-2">{{ app.title }}</h3>
            <p class="text-sm text-gray-500 leading-relaxed">{{ app.desc }}</p>
            <img
              v-if="app.screenshot"
              :src="app.screenshot"
              :alt="`${app.title}のゲーム画面`"
              class="mt-4 w-full rounded-xl border border-gray-100"
            />
            <div class="flex-1" />
            <div class="flex flex-wrap gap-2 mt-4">
              <span
                v-for="tag in app.tags"
                :key="tag"
                class="text-xs px-2 py-1 rounded-full bg-gray-50 text-gray-500 border border-gray-100"
              >{{ tag }}</span>
            </div>
            <a
              v-if="app.url"
              :href="app.url"
              :target="isExternal(app.url) ? '_blank' : undefined"
              :rel="isExternal(app.url) ? 'noopener noreferrer' : undefined"
              class="mt-4 inline-flex items-center gap-1 text-xs text-primary hover:underline"
            >
              {{ isExternal(app.url) ? 'アプリ詳細を見る →' : 'ページを見る →' }}
            </a>
          </div>
        </div>
      </div>
    </section>

    <!-- Skills -->
    <section class="py-24 px-6 bg-white">
      <div class="max-w-4xl mx-auto">
        <div class="text-center mb-16">
          <span class="text-xs font-semibold tracking-widest text-primary uppercase">Skills</span>
          <h2 class="text-3xl font-bold mt-2 text-gray-900">{{ texts.profile_skills_heading || '技術スタック' }}</h2>
        </div>

        <div class="space-y-10">
          <div v-for="group in skillGroups" :key="group.label">
            <div class="text-xs font-semibold text-gray-400 tracking-widest uppercase mb-3">{{ group.label }}</div>
            <div class="flex flex-wrap gap-2">
              <span
                v-for="skill in group.items"
                :key="skill"
                class="px-4 py-2 rounded-full border text-sm transition-colors"
                :class="group.primary
                  ? 'border-primary/30 text-primary bg-blue-50 hover:bg-primary hover:text-white'
                  : 'border-gray-200 text-gray-500 hover:border-gray-400'"
              >
                {{ skill }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- CTA -->
    <section class="py-24 px-6 bg-[#080c14]">
      <div class="max-w-2xl mx-auto text-center">
        <h2 class="text-3xl sm:text-4xl font-black text-white mb-6 leading-tight whitespace-pre-line">
          {{ texts.profile_cta_title || '一緒に何か\nつくりませんか？' }}
        </h2>
        <p class="text-white/40 mb-10">{{ texts.profile_cta_subtitle || '初回相談は無料。気軽にメッセージください。' }}</p>
        <router-link
          to="/contact"
          class="inline-flex items-center gap-2 bg-white text-gray-900 px-8 py-4 rounded-full font-semibold text-sm hover:bg-gray-100 transition-colors"
        >
          お問い合わせ →
        </router-link>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { fetchSiteContent, type ContentItem } from '../lib/api'

interface ValueItem {
  emoji: string
  title: string
  desc: string
}

interface CareerItem {
  year: string
  company: string
  desc: string
  projects: string[]
}

interface AppItem {
  category: string
  date: string
  title: string
  desc: string
  emoji?: string
  tags: string[]
  url?: string
  icon?: string
  screenshot?: string
}

interface SkillGroup {
  label: string
  primary: boolean
  items: string[]
}

const texts = ref<Record<string, string>>({})
const values = ref<ValueItem[]>([])
const career = ref<CareerItem[]>([])
const apps = ref<AppItem[]>([])
const skillGroups = ref<SkillGroup[]>([])

// 画像はLabからアップロードされたものを優先し、無ければ導入時の初期データ（data.icon_url等）を使う
function toApp(item: ContentItem): AppItem {
  const data = item.data as any
  return {
    ...data,
    icon: item.image || data.icon_url,
    screenshot: item.image_secondary || data.screenshot_url,
  }
}

function isExternal(url: string): boolean {
  return /^https?:\/\//i.test(url)
}

async function load() {
  try {
    const content = await fetchSiteContent()
    texts.value = content.texts
    values.value = (content.items.profile_values ?? []).map((i) => i.data as unknown as ValueItem)
    career.value = (content.items.profile_career ?? []).map((i) => i.data as unknown as CareerItem)
    apps.value = (content.items.profile_apps ?? []).map(toApp)
    skillGroups.value = (content.items.profile_skills ?? []).map((i) => i.data as unknown as SkillGroup)
  } catch {
    // 取得失敗時は空表示のまま
  }
}

onMounted(load)
</script>
