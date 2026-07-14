<template>
  <div class="max-w-5xl mx-auto px-6 py-10">
    <div class="mb-6 flex items-center justify-between">
      <div>
        <h2 class="text-xl font-bold">権限管理</h2>
        <p class="text-sm text-white/60 mt-1">ロールごとにメニュー権限とメンバーを管理する</p>
      </div>
      <button
        v-if="canWrite('roles')"
        type="button"
        class="text-sm px-4 py-2 rounded-full bg-primary text-black font-medium hover:opacity-90 transition-opacity"
        @click="openCreateForm"
      >
        + 新規ロール
      </button>
    </div>

    <div v-if="errorMsg" class="mb-6 bg-red-500/10 border border-red-500/30 text-red-300 rounded-xl p-4 text-sm">
      {{ errorMsg }}
    </div>

    <div v-if="loading" class="text-center text-white/60 py-20 text-sm">読み込み中...</div>

    <div v-else-if="roles.length === 0" class="text-center text-white/60 py-20 text-sm">
      ロールがまだありません
    </div>

    <template v-else>
      <div class="overflow-x-auto rounded-2xl border border-white/10">
        <table class="w-full text-sm">
          <thead class="bg-white/5 text-white/70 text-xs">
            <tr>
              <th class="px-4 py-3 text-left font-medium">ロール名</th>
              <th class="px-4 py-3 text-left font-medium">メンバー数</th>
              <th class="px-4 py-3 text-left font-medium">更新日時</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-white/10">
            <tr
              v-for="role in roles"
              :key="role.id"
              class="cursor-pointer hover:bg-white/5"
              @click="openEditForm(role)"
            >
              <td class="px-4 py-3 max-w-[200px] truncate">{{ role.name }}</td>
              <td class="px-4 py-3 text-white/80">{{ role.member_ids.length }}人</td>
              <td class="px-4 py-3 whitespace-nowrap text-white/80">{{ formatDate(role.updated_at) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </template>

    <div
      v-if="showForm"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4"
      @click.self="closeForm"
    >
      <div class="w-full max-w-2xl max-h-[90vh] overflow-y-auto rounded-2xl border border-white/10 bg-[#0c1220] p-8 space-y-5">
        <div class="flex items-center justify-between">
          <h3 class="font-semibold text-base">{{ editingRole ? 'ロールを編集' : 'ロールを新規作成' }}</h3>
          <button type="button" class="text-white/60 hover:text-white transition-colors" @click="closeForm">✕</button>
        </div>

        <div>
          <label class="block text-xs text-white/60 mb-1">ロール名</label>
          <input
            v-model="form.name"
            type="text"
            :disabled="!canWrite('roles')"
            class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2.5 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50"
          />
        </div>

        <div>
          <label class="block text-xs text-white/60 mb-2">メニュー権限</label>
          <div class="space-y-2">
            <div
              v-for="perm in form.menu_permissions"
              :key="perm.menu_key"
              class="flex items-center justify-between rounded-lg border border-white/10 bg-white/5 px-3 py-2"
            >
              <span class="text-sm">{{ menuLabel(perm.menu_key) }}</span>
              <select
                v-model.number="perm.level"
                :disabled="!canWrite('roles')"
                class="rounded-lg bg-white/5 border border-white/10 px-2 py-1.5 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50"
              >
                <option :value="LEVEL_NONE">権限なし</option>
                <option :value="LEVEL_READ">参照</option>
                <option :value="LEVEL_WRITE">参照・編集</option>
              </select>
            </div>
          </div>
        </div>

        <div>
          <label class="block text-xs text-white/60 mb-2">メンバー</label>
          <div class="flex flex-wrap gap-3">
            <label
              v-for="user in users"
              :key="user.id"
              class="flex items-center gap-2 text-sm px-3 py-1.5 rounded-lg border border-white/10 bg-white/5"
            >
              <input
                type="checkbox"
                :checked="form.member_ids.includes(user.id)"
                :disabled="!canWrite('roles')"
                @change="toggleMember(user.id)"
              />
              {{ user.username }}
            </label>
            <span v-if="users.length === 0" class="text-xs text-white/50">
              ユーザーがまだいません（ユーザー管理から作成できます）
            </span>
          </div>
        </div>

        <div class="flex items-center justify-between pt-2">
          <button
            v-if="editingRole && canWrite('roles')"
            type="button"
            class="text-xs text-red-400/70 hover:text-red-400 transition-colors"
            @click="removeRole(editingRole)"
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
              {{ canWrite('roles') ? 'キャンセル' : '閉じる' }}
            </button>
            <button
              v-if="canWrite('roles')"
              type="button"
              class="text-sm px-4 py-2 rounded-full bg-primary text-black font-medium hover:opacity-90 transition-opacity disabled:opacity-50"
              :disabled="!form.name || saving"
              @click="submitForm"
            >
              {{ editingRole ? '更新する' : '作成する' }}
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
  createRole,
  deleteRole,
  fetchRoles,
  fetchUsers,
  updateRole,
  type LabUser,
  type Role,
  type RoleInput,
} from '../../lib/api'
import { canWrite, LEVEL_NONE, LEVEL_READ, LEVEL_WRITE, MENU_OPTIONS } from '../../lib/permissions'

const roles = ref<Role[]>([])
const users = ref<LabUser[]>([])
const loading = ref(true)
const saving = ref(false)
const errorMsg = ref('')
const showForm = ref(false)
const editingRole = ref<Role | null>(null)

const form = reactive<RoleInput>({
  name: '',
  menu_permissions: MENU_OPTIONS.map((opt) => ({ menu_key: opt.key, level: LEVEL_NONE })),
  member_ids: [],
})

function menuLabel(menuKey: string): string {
  return MENU_OPTIONS.find((opt) => opt.key === menuKey)?.label ?? menuKey
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleString('ja-JP', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  })
}

function toggleMember(userId: number) {
  const idx = form.member_ids.indexOf(userId)
  if (idx === -1) {
    form.member_ids.push(userId)
  } else {
    form.member_ids.splice(idx, 1)
  }
}

async function loadData() {
  loading.value = true
  errorMsg.value = ''
  try {
    const [roleList, userList] = await Promise.all([fetchRoles(), fetchUsers()])
    roles.value = roleList
    users.value = userList
  } catch {
    errorMsg.value = 'ロール一覧の取得に失敗しました。'
  } finally {
    loading.value = false
  }
}

function resetForm() {
  form.name = ''
  form.menu_permissions = MENU_OPTIONS.map((opt) => ({ menu_key: opt.key, level: LEVEL_NONE }))
  form.member_ids = []
}

function openCreateForm() {
  editingRole.value = null
  resetForm()
  showForm.value = true
}

function openEditForm(role: Role) {
  editingRole.value = role
  form.name = role.name
  form.menu_permissions = MENU_OPTIONS.map((opt) => {
    const existing = role.menu_permissions.find((p) => p.menu_key === opt.key)
    return { menu_key: opt.key, level: existing?.level ?? LEVEL_NONE }
  })
  form.member_ids = [...role.member_ids]
  showForm.value = true
}

function closeForm() {
  showForm.value = false
  editingRole.value = null
}

async function submitForm() {
  saving.value = true
  errorMsg.value = ''
  try {
    if (editingRole.value) {
      const updated = await updateRole(editingRole.value.id, { ...form })
      const idx = roles.value.findIndex((r) => r.id === updated.id)
      if (idx !== -1) roles.value[idx] = updated
    } else {
      const created = await createRole({ ...form })
      roles.value.unshift(created)
    }
    closeForm()
  } catch {
    errorMsg.value = '保存に失敗しました。'
  } finally {
    saving.value = false
  }
}

async function removeRole(role: Role) {
  if (!confirm(`「${role.name}」を削除しますか？`)) return
  try {
    await deleteRole(role.id)
    roles.value = roles.value.filter((r) => r.id !== role.id)
    closeForm()
  } catch {
    errorMsg.value = '削除に失敗しました。'
  }
}

onMounted(loadData)
</script>
