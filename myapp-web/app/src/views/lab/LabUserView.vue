<template>
  <div class="max-w-5xl mx-auto px-6 py-10">
    <div class="mb-6 flex items-center justify-between">
      <div>
        <h2 class="text-xl font-bold">ユーザー管理</h2>
        <p class="text-sm text-white/60 mt-1">Labにログインできるユーザーとロールを管理する</p>
      </div>
      <button
        v-if="canWrite('users')"
        type="button"
        class="text-sm px-4 py-2 rounded-full bg-primary text-black font-medium hover:opacity-90 transition-opacity"
        @click="openCreateForm"
      >
        + 新規ユーザー招待
      </button>
    </div>

    <div v-if="errorMsg" class="mb-6 bg-red-500/10 border border-red-500/30 text-red-300 rounded-xl p-4 text-sm">
      {{ errorMsg }}
    </div>

    <div v-if="loading" class="text-center text-white/60 py-20 text-sm">読み込み中...</div>

    <div v-else-if="users.length === 0" class="text-center text-white/60 py-20 text-sm">
      ユーザーがいません
    </div>

    <template v-else>
      <div class="overflow-x-auto rounded-2xl border border-white/10">
        <table class="w-full text-sm">
          <thead class="bg-white/5 text-white/70 text-xs">
            <tr>
              <th class="px-4 py-3 text-left font-medium">ユーザー名</th>
              <th class="px-4 py-3 text-left font-medium">メールアドレス</th>
              <th class="px-4 py-3 text-left font-medium">ロール</th>
              <th class="px-4 py-3 text-left font-medium">状態</th>
              <th class="px-4 py-3 text-left font-medium">最終ログイン</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-white/10">
            <tr
              v-for="user in users"
              :key="user.id"
              class="cursor-pointer hover:bg-white/5"
              @click="openEditForm(user)"
            >
              <td class="px-4 py-3">{{ user.username }}</td>
              <td class="px-4 py-3 text-white/80">{{ user.email || '-' }}</td>
              <td class="px-4 py-3 text-white/80">{{ roleNames(user.role_ids) }}</td>
              <td class="px-4 py-3">
                <span
                  class="text-xs px-3 py-1 rounded-full border"
                  :class="user.is_active
                    ? 'border-green-500/40 text-green-400 bg-green-500/10'
                    : 'border-white/20 text-white/50'"
                >
                  {{ user.is_superuser ? 'スーパーユーザー' : (user.is_active ? '有効' : '無効') }}
                </span>
              </td>
              <td class="px-4 py-3 whitespace-nowrap text-white/80">
                {{ user.last_login ? formatDate(user.last_login) : '未ログイン' }}
              </td>
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
          <h3 class="font-semibold text-base">{{ editingUser ? 'ユーザーを編集' : 'ユーザーを新規招待' }}</h3>
          <button type="button" class="text-white/60 hover:text-white transition-colors" @click="closeForm">✕</button>
        </div>

        <p v-if="!editingUser" class="text-xs text-white/60">
          作成すると、入力したメールアドレス宛にパスワード設定用の招待メールが送信されます。
        </p>

        <div class="flex gap-4">
          <div class="flex-1">
            <label class="block text-xs text-white/60 mb-1">ユーザー名</label>
            <input
              v-model="form.username"
              type="text"
              :disabled="!canWrite('users')"
              class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2.5 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50"
            />
          </div>
          <div class="flex-1">
            <label class="block text-xs text-white/60 mb-1">メールアドレス</label>
            <input
              v-model="form.email"
              type="email"
              :disabled="!canWrite('users')"
              class="w-full rounded-lg bg-white/5 border border-white/10 px-3 py-2.5 text-sm focus:outline-none focus:border-primary/60 disabled:opacity-50"
            />
          </div>
        </div>

        <div class="flex gap-6">
          <label class="flex items-center gap-2 text-sm">
            <input v-model="form.is_active" type="checkbox" :disabled="!canWrite('users')" />
            有効
          </label>
          <label class="flex items-center gap-2 text-sm">
            <input v-model="form.is_staff" type="checkbox" :disabled="!canWrite('users')" />
            管理者（全メニューにフルアクセス）
          </label>
        </div>

        <div>
          <label class="block text-xs text-white/60 mb-2">ロール</label>
          <div class="flex flex-wrap gap-3">
            <label
              v-for="role in roles"
              :key="role.id"
              class="flex items-center gap-2 text-sm px-3 py-1.5 rounded-lg border border-white/10 bg-white/5"
            >
              <input
                type="checkbox"
                :value="role.id"
                :checked="form.role_ids.includes(role.id)"
                :disabled="!canWrite('users')"
                @change="toggleRole(role.id)"
              />
              {{ role.name }}
            </label>
            <span v-if="roles.length === 0" class="text-xs text-white/50">
              ロールがまだありません（権限管理から作成できます）
            </span>
          </div>
        </div>

        <div v-if="editingUser && canWrite('users')" class="flex items-center gap-2">
          <button
            type="button"
            class="text-xs px-3 py-1 rounded-full border border-primary/40 text-primary hover:bg-primary/10 transition-colors disabled:opacity-50"
            :disabled="inviting || !form.email"
            @click="resendInvite(editingUser)"
          >
            {{ inviting ? '送信中...' : '招待メール再送' }}
          </button>
          <span class="text-xs text-white/50">リンク期限切れ時などに再送できます</span>
        </div>

        <div class="flex items-center justify-between pt-2">
          <button
            v-if="editingUser && canWrite('users') && !editingUser.is_superuser"
            type="button"
            class="text-xs text-red-400/70 hover:text-red-400 transition-colors"
            @click="removeUser(editingUser)"
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
              {{ canWrite('users') ? 'キャンセル' : '閉じる' }}
            </button>
            <button
              v-if="canWrite('users')"
              type="button"
              class="text-sm px-4 py-2 rounded-full bg-primary text-black font-medium hover:opacity-90 transition-opacity disabled:opacity-50"
              :disabled="!form.username || saving"
              @click="submitForm"
            >
              {{ editingUser ? '更新する' : '招待メールを送信' }}
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
  createUser,
  deleteUser,
  fetchRoles,
  fetchUsers,
  inviteUser,
  updateUser,
  type LabUser,
  type LabUserInput,
  type Role,
} from '../../lib/api'
import { canWrite } from '../../lib/permissions'

const users = ref<LabUser[]>([])
const roles = ref<Role[]>([])
const loading = ref(true)
const saving = ref(false)
const inviting = ref(false)
const errorMsg = ref('')
const showForm = ref(false)
const editingUser = ref<LabUser | null>(null)

const form = reactive<LabUserInput>({
  username: '',
  email: '',
  is_active: true,
  is_staff: false,
  role_ids: [],
})

function formatDate(iso: string): string {
  return new Date(iso).toLocaleString('ja-JP', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  })
}

function roleNames(roleIds: number[]): string {
  if (roleIds.length === 0) return '-'
  return roleIds
    .map((id) => roles.value.find((r) => r.id === id)?.name)
    .filter(Boolean)
    .join(', ')
}

function toggleRole(roleId: number) {
  const idx = form.role_ids.indexOf(roleId)
  if (idx === -1) {
    form.role_ids.push(roleId)
  } else {
    form.role_ids.splice(idx, 1)
  }
}

async function loadData() {
  loading.value = true
  errorMsg.value = ''
  try {
    const [userList, roleList] = await Promise.all([fetchUsers(), fetchRoles()])
    users.value = userList
    roles.value = roleList
  } catch {
    errorMsg.value = 'ユーザー一覧の取得に失敗しました。'
  } finally {
    loading.value = false
  }
}

function resetForm() {
  form.username = ''
  form.email = ''
  form.is_active = true
  form.is_staff = false
  form.role_ids = []
}

function openCreateForm() {
  editingUser.value = null
  resetForm()
  showForm.value = true
}

function openEditForm(user: LabUser) {
  editingUser.value = user
  form.username = user.username
  form.email = user.email
  form.is_active = user.is_active
  form.is_staff = user.is_staff
  form.role_ids = [...user.role_ids]
  showForm.value = true
}

function closeForm() {
  showForm.value = false
  editingUser.value = null
}

async function submitForm() {
  saving.value = true
  errorMsg.value = ''
  try {
    if (editingUser.value) {
      const updated = await updateUser(editingUser.value.id, { ...form })
      const idx = users.value.findIndex((u) => u.id === updated.id)
      if (idx !== -1) users.value[idx] = updated
    } else {
      const created = await createUser({ ...form })
      users.value.unshift(created)
    }
    closeForm()
  } catch {
    errorMsg.value = '保存に失敗しました。'
  } finally {
    saving.value = false
  }
}

async function removeUser(user: LabUser) {
  if (!confirm(`「${user.username}」を削除しますか？`)) return
  try {
    await deleteUser(user.id)
    users.value = users.value.filter((u) => u.id !== user.id)
    closeForm()
  } catch {
    errorMsg.value = '削除に失敗しました。'
  }
}

async function resendInvite(user: LabUser) {
  inviting.value = true
  errorMsg.value = ''
  try {
    await inviteUser(user.id)
    alert('招待メールを再送しました。')
  } catch {
    errorMsg.value = '招待メールの再送に失敗しました。'
  } finally {
    inviting.value = false
  }
}

onMounted(loadData)
</script>
