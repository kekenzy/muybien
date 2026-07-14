import axios from 'axios'
import { clearTokens, getAccessToken, getRefreshToken, setTokens } from './auth'
import { clearPermissions } from './permissions'

const api = axios.create({
  baseURL: '/v1/api',
})

api.interceptors.request.use((config) => {
  const token = getAccessToken()
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const original = error.config
    if (error.response?.status !== 401 || original._retry) {
      return Promise.reject(error)
    }

    const refresh = getRefreshToken()
    if (!refresh) {
      clearTokens()
      return Promise.reject(error)
    }

    original._retry = true
    try {
      const { data } = await axios.post('/v1/api/auth/refresh', { refresh })
      setTokens(data.access, refresh)
      original.headers.Authorization = `Bearer ${data.access}`
      return api(original)
    } catch {
      clearTokens()
      window.location.href = '/lab/login'
      return Promise.reject(error)
    }
  },
)

export default api

export interface ContactMessage {
  id: number
  name: string
  email: string
  subject: string
  message: string
  created_at: string
  is_replied: boolean
  customer_id: number | null
}

export interface LoginResponse {
  access: string
  refresh: string
}

export interface MeResponse {
  username: string
  email: string
  is_staff: boolean
  is_superuser: boolean
  permissions: Record<string, number>
}

export async function login(username: string, password: string): Promise<LoginResponse> {
  const { data } = await api.post<LoginResponse>('/auth/login', { username, password })
  setTokens(data.access, data.refresh)
  return data
}

export async function fetchMe(): Promise<MeResponse> {
  const { data } = await api.get<MeResponse>('/auth/me')
  return data
}

export async function fetchContacts(): Promise<ContactMessage[]> {
  const { data } = await api.get<ContactMessage[]>('/lab/contacts')
  return data
}

export async function updateContact(id: number, is_replied: boolean): Promise<ContactMessage> {
  const { data } = await api.patch<ContactMessage>(`/lab/contacts/${id}`, { is_replied })
  return data
}

export function logout(): void {
  clearTokens()
  clearPermissions()
}

export async function setPassword(uid: string, token: string, password: string): Promise<void> {
  await api.post('/lab/set-password', { uid, token, password })
}

export type TaskStatus = 'todo' | 'in_progress' | 'done'

export interface LabTask {
  id: number
  title: string
  description: string
  status: TaskStatus
  due_date: string | null
  created_at: string
  updated_at: string
}

export interface LabTaskInput {
  title: string
  description: string
  status: TaskStatus
  due_date: string | null
}

export interface DiaryEntry {
  id: number
  date: string
  title: string
  content: string
  created_at: string
  updated_at: string
}

export interface DiaryEntryInput {
  date: string
  title: string
  content: string
}

export async function fetchTasks(): Promise<LabTask[]> {
  const { data } = await api.get<LabTask[]>('/lab/tasks')
  return data
}

export async function createTask(input: LabTaskInput): Promise<LabTask> {
  const { data } = await api.post<LabTask>('/lab/tasks', input)
  return data
}

export async function updateTask(id: number, input: LabTaskInput): Promise<LabTask> {
  const { data } = await api.patch<LabTask>(`/lab/tasks/${id}`, input)
  return data
}

export async function deleteTask(id: number): Promise<void> {
  await api.delete(`/lab/tasks/${id}`)
}

export async function fetchDiaries(year: number, month: number): Promise<DiaryEntry[]> {
  const { data } = await api.get<DiaryEntry[]>('/lab/diaries', { params: { year, month } })
  return data
}

export async function createDiary(input: DiaryEntryInput): Promise<DiaryEntry> {
  const { data } = await api.post<DiaryEntry>('/lab/diaries', input)
  return data
}

export async function updateDiary(id: number, input: DiaryEntryInput): Promise<DiaryEntry> {
  const { data } = await api.patch<DiaryEntry>(`/lab/diaries/${id}`, input)
  return data
}

export async function deleteDiary(id: number): Promise<void> {
  await api.delete(`/lab/diaries/${id}`)
}

export interface Customer {
  id: number
  name: string
  email: string
  phone: string
  company: string
  memo: string
  source_contact: number | null
  has_login: boolean
  created_at: string
  updated_at: string
}

export interface CustomerInput {
  name: string
  email: string
  phone: string
  company: string
  memo: string
  source_contact?: number | null
}

export async function fetchCustomers(): Promise<Customer[]> {
  const { data } = await api.get<Customer[]>('/lab/customers')
  return data
}

export async function createCustomer(input: CustomerInput): Promise<Customer> {
  const { data } = await api.post<Customer>('/lab/customers', input)
  return data
}

export async function updateCustomer(id: number, input: CustomerInput): Promise<Customer> {
  const { data } = await api.patch<Customer>(`/lab/customers/${id}`, input)
  return data
}

export async function deleteCustomer(id: number): Promise<void> {
  await api.delete(`/lab/customers/${id}`)
}

export async function inviteCustomer(id: number): Promise<Customer> {
  const { data } = await api.post<Customer>(`/lab/customers/${id}/invite`)
  return data
}

export interface LabUser {
  id: number
  username: string
  email: string
  is_active: boolean
  is_staff: boolean
  is_superuser: boolean
  role_ids: number[]
  date_joined: string
  last_login: string | null
}

export interface LabUserInput {
  username: string
  email: string
  is_active: boolean
  is_staff: boolean
  role_ids: number[]
}

export async function fetchUsers(): Promise<LabUser[]> {
  const { data } = await api.get<LabUser[]>('/lab/users')
  return data
}

export async function createUser(input: LabUserInput): Promise<LabUser> {
  const { data } = await api.post<LabUser>('/lab/users', input)
  return data
}

export async function updateUser(id: number, input: LabUserInput): Promise<LabUser> {
  const { data } = await api.patch<LabUser>(`/lab/users/${id}`, input)
  return data
}

export async function deleteUser(id: number): Promise<void> {
  await api.delete(`/lab/users/${id}`)
}

export interface RoleMenuPermissionItem {
  menu_key: string
  level: number
}

export interface Role {
  id: number
  name: string
  menu_permissions: RoleMenuPermissionItem[]
  member_ids: number[]
  created_at: string
  updated_at: string
}

export interface RoleInput {
  name: string
  menu_permissions: RoleMenuPermissionItem[]
  member_ids: number[]
}

export async function fetchRoles(): Promise<Role[]> {
  const { data } = await api.get<Role[]>('/lab/roles')
  return data
}

export async function createRole(input: RoleInput): Promise<Role> {
  const { data } = await api.post<Role>('/lab/roles', input)
  return data
}

export async function updateRole(id: number, input: RoleInput): Promise<Role> {
  const { data } = await api.patch<Role>(`/lab/roles/${id}`, input)
  return data
}

export async function deleteRole(id: number): Promise<void> {
  await api.delete(`/lab/roles/${id}`)
}
