import { reactive } from 'vue'

export type MenuKey = 'contacts' | 'customers' | 'tasks' | 'diary' | 'reservations' | 'users' | 'roles'

export const MENU_OPTIONS: { key: MenuKey; label: string }[] = [
  { key: 'contacts', label: 'お問い合わせ一覧' },
  { key: 'customers', label: '顧客管理' },
  { key: 'tasks', label: 'タスク一覧' },
  { key: 'diary', label: '日記' },
  { key: 'reservations', label: '予約管理' },
  { key: 'users', label: 'ユーザー管理' },
  { key: 'roles', label: '権限管理' },
]

export const LEVEL_NONE = 0
export const LEVEL_READ = 1
export const LEVEL_WRITE = 2

const STORAGE_KEY = 'lab_permissions'

interface PermissionState {
  isSuperuser: boolean
  isStaff: boolean
  levels: Record<string, number>
}

function load(): PermissionState {
  const raw = localStorage.getItem(STORAGE_KEY)
  if (!raw) return { isSuperuser: false, isStaff: false, levels: {} }
  try {
    return JSON.parse(raw)
  } catch {
    return { isSuperuser: false, isStaff: false, levels: {} }
  }
}

export const permissionState = reactive<PermissionState>(load())

export function setPermissions(isSuperuser: boolean, isStaff: boolean, levels: Record<string, number>): void {
  permissionState.isSuperuser = isSuperuser
  permissionState.isStaff = isStaff
  permissionState.levels = levels
  localStorage.setItem(STORAGE_KEY, JSON.stringify({ isSuperuser, isStaff, levels }))
}

export function clearPermissions(): void {
  permissionState.isSuperuser = false
  permissionState.isStaff = false
  permissionState.levels = {}
  localStorage.removeItem(STORAGE_KEY)
}

export function canRead(menuKey: MenuKey): boolean {
  if (permissionState.isSuperuser || permissionState.isStaff) return true
  return (permissionState.levels[menuKey] ?? LEVEL_NONE) >= LEVEL_READ
}

export function canWrite(menuKey: MenuKey): boolean {
  if (permissionState.isSuperuser || permissionState.isStaff) return true
  return (permissionState.levels[menuKey] ?? LEVEL_NONE) >= LEVEL_WRITE
}
