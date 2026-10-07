<template>
  <Teleport to="body">
    <div
      class="fixed inset-0 z-[60] flex flex-col bg-black/95 select-none"
      @touchstart.passive="onTouchStart"
      @touchend="onTouchEnd"
    >
      <div class="flex items-center justify-between px-4 py-3 text-white/80">
        <span class="text-sm">{{ urls.length > 1 ? `${index + 1} / ${urls.length}` : '' }}</span>
        <button type="button" class="p-1 hover:text-white" aria-label="閉じる" @click="emit('close')">
          <X class="h-6 w-6" />
        </button>
      </div>
      <div class="relative flex min-h-0 flex-1 items-center justify-center px-4 pb-6" @click.self="emit('close')">
        <img :src="urls[index]" alt="" class="max-h-full max-w-full object-contain" />
        <button
          v-if="urls.length > 1"
          type="button"
          class="absolute left-2 top-1/2 -translate-y-1/2 rounded-full bg-black/50 p-2 text-white/80 hover:text-white disabled:opacity-30"
          aria-label="前の写真"
          :disabled="index === 0"
          @click="go(-1)"
        >
          <ChevronLeft class="h-7 w-7" />
        </button>
        <button
          v-if="urls.length > 1"
          type="button"
          class="absolute right-2 top-1/2 -translate-y-1/2 rounded-full bg-black/50 p-2 text-white/80 hover:text-white disabled:opacity-30"
          aria-label="次の写真"
          :disabled="index === urls.length - 1"
          @click="go(1)"
        >
          <ChevronRight class="h-7 w-7" />
        </button>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref } from 'vue'
import { ChevronLeft, ChevronRight, X } from 'lucide-vue-next'

const props = defineProps<{ urls: string[]; startIndex?: number }>()
const emit = defineEmits<{ close: [] }>()

const index = ref(Math.min(Math.max(props.startIndex ?? 0, 0), props.urls.length - 1))

function go(step: number) {
  const next = index.value + step
  if (next >= 0 && next < props.urls.length) index.value = next
}

function onKeydown(event: KeyboardEvent) {
  if (event.key === 'ArrowLeft') go(-1)
  else if (event.key === 'ArrowRight') go(1)
  else if (event.key === 'Escape') emit('close')
}

// スマホのブラウザでは左右スワイプで切り替える（ピンチ中・拡大中は無視）
let touchStartX: number | null = null
let touchStartY = 0

function onTouchStart(event: TouchEvent) {
  if (event.touches.length !== 1 || (window.visualViewport?.scale ?? 1) > 1) {
    touchStartX = null
    return
  }
  touchStartX = event.touches[0].clientX
  touchStartY = event.touches[0].clientY
}

function onTouchEnd(event: TouchEvent) {
  if (touchStartX === null) return
  const dx = event.changedTouches[0].clientX - touchStartX
  const dy = event.changedTouches[0].clientY - touchStartY
  touchStartX = null
  if (Math.abs(dx) < 50 || Math.abs(dx) < Math.abs(dy)) return
  go(dx < 0 ? 1 : -1)
}

onMounted(() => window.addEventListener('keydown', onKeydown))
onBeforeUnmount(() => window.removeEventListener('keydown', onKeydown))
</script>
