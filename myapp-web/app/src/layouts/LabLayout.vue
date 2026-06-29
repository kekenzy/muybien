<template>
  <div class="min-h-screen bg-[#080c14] text-white flex flex-col">
    <header class="border-b border-white/10 bg-[#080c14]/90 backdrop-blur sticky top-0 z-50">
      <div class="max-w-5xl mx-auto px-6 h-14 flex items-center justify-between">
        <router-link to="/lab" class="font-bold text-lg tracking-tight">
          🔬 永井のLab
        </router-link>
        <div v-if="showNav" class="flex items-center gap-4">
          <span v-if="username" class="text-xs text-white/40">{{ username }}</span>
          <button
            type="button"
            class="text-xs text-white/50 hover:text-white transition-colors"
            @click="handleLogout"
          >
            ログアウト
          </button>
        </div>
      </div>
    </header>

    <main class="flex-1">
      <router-view />
    </main>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { isLoggedIn } from '../lib/auth'
import { logout } from '../lib/api'

const route = useRoute()
const router = useRouter()
const username = ref('')

const showNav = computed(() => route.name !== 'lab-login' && isLoggedIn())

watch(
  () => route.path,
  () => {
    const stored = sessionStorage.getItem('lab_username')
    username.value = stored ?? ''
  },
  { immediate: true },
)

function handleLogout() {
  logout()
  sessionStorage.removeItem('lab_username')
  router.push('/lab/login')
}
</script>
