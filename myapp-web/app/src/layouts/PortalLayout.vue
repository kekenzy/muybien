<template>
  <div class="min-h-screen bg-[#080c14] text-white flex flex-col">
    <header class="border-b border-white/10 bg-[#080c14]/90 backdrop-blur sticky top-0 z-50">
      <div class="max-w-5xl mx-auto px-4 sm:px-6 h-14 flex items-center justify-between gap-3">
        <div class="flex items-center gap-2">
          <button
            v-if="showNav"
            type="button"
            class="sm:hidden flex items-center justify-center w-9 h-9 -ml-1.5 rounded-lg text-white/80 hover:text-white hover:bg-white/10 transition-colors"
            :aria-expanded="menuOpen"
            aria-controls="portal-mobile-nav"
            aria-label="メニュー"
            @click="menuOpen = !menuOpen"
          >
            <Menu v-if="!menuOpen" class="w-5 h-5" />
            <X v-else class="w-5 h-5" />
          </button>
          <router-link to="/portal" class="font-bold text-lg tracking-tight">
            🗓️ お客様ポータル
          </router-link>
        </div>
        <div v-if="showNav" class="flex items-center gap-4">
          <span v-if="username" class="text-xs text-white/60 hidden sm:inline">{{ username }}</span>
          <button
            type="button"
            class="text-xs text-white/70 hover:text-white transition-colors"
            @click="handleLogout"
          >
            ログアウト
          </button>
        </div>
      </div>

      <Transition
        enter-active-class="transition duration-200 ease-out"
        enter-from-class="opacity-0 -translate-y-2"
        enter-to-class="opacity-100 translate-y-0"
        leave-active-class="transition duration-150 ease-in"
        leave-from-class="opacity-100 translate-y-0"
        leave-to-class="opacity-0 -translate-y-2"
      >
        <nav
          v-if="showNav && menuOpen"
          id="portal-mobile-nav"
          class="sm:hidden border-t border-white/10 bg-[#080c14] px-4 py-3"
        >
          <div class="flex flex-col gap-1">
            <router-link
              v-for="item in navItems"
              :key="item.name"
              :to="item.to"
              class="rounded-lg px-3 py-2.5 text-sm transition-colors"
              :class="route.name === item.name
                ? 'bg-white/10 text-white font-medium'
                : 'text-white/70 hover:bg-white/5 hover:text-white'"
            >
              {{ item.label }}
            </router-link>
          </div>
        </nav>
      </Transition>
    </header>

    <div class="flex-1 flex">
      <aside v-if="showNav" class="w-48 shrink-0 border-r border-white/10 py-6 px-3 hidden sm:block">
        <nav class="flex flex-col gap-1">
          <router-link
            v-for="item in navItems"
            :key="item.name"
            :to="item.to"
            class="rounded-lg px-3 py-2 text-sm transition-colors"
            :class="route.name === item.name
              ? 'bg-white/10 text-white font-medium'
              : 'text-white/70 hover:bg-white/5 hover:text-white'"
          >
            {{ item.label }}
          </router-link>
        </nav>
      </aside>

      <main class="flex-1 min-w-0">
        <router-view />
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Menu, X } from 'lucide-vue-next'
import { isPortalLoggedIn } from '../lib/portalAuth'
import { portalLogout } from '../lib/portalApi'

const route = useRoute()
const router = useRouter()
const username = ref('')
const menuOpen = ref(false)

const showNav = computed(() => route.name !== 'portal-login' && isPortalLoggedIn())

const navItems = [
  { name: 'portal-reservations', to: '/portal/reservations', label: '予約管理' },
  { name: 'portal-payment', to: '/portal/payment', label: '決済管理' },
]

watch(
  () => route.path,
  () => {
    const stored = sessionStorage.getItem('portal_username')
    username.value = stored ?? ''
    menuOpen.value = false
  },
  { immediate: true },
)

watch(menuOpen, (open) => {
  document.body.style.overflow = open ? 'hidden' : ''
})

function handleLogout() {
  portalLogout()
  sessionStorage.removeItem('portal_username')
  router.push('/portal/login')
}
</script>
