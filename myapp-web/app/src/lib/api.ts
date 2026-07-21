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
  is_customer: boolean
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

export async function setPassword(
  uid: string,
  token: string,
  password: string,
): Promise<{ detail: string; is_customer: boolean }> {
  // 未認証エンドポイント。ローカルに残った JWT を付けない（無効トークンだと AllowAny でも 401 になる）
  const { data } = await axios.post<{ detail: string; is_customer: boolean }>(
    '/v1/api/lab/set-password',
    { uid, token, password },
  )
  return data
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

export async function inviteUser(id: number): Promise<LabUser> {
  const { data } = await api.post<LabUser>(`/lab/users/${id}/invite`)
  return data
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

export type ReservationStatus = 'confirmed' | 'cancelled'

export interface LabReservation {
  id: number
  customer: number
  customer_name: string
  customer_email: string
  start_at: string
  end_at: string
  status: ReservationStatus
  note: string
  created_at: string
  updated_at: string
  cancelled_at: string | null
}

export async function fetchLabReservations(): Promise<LabReservation[]> {
  const { data } = await api.get<LabReservation[]>('/lab/reservations')
  return data
}

export async function cancelLabReservation(id: number): Promise<void> {
  await api.delete(`/lab/reservations/${id}`)
}

export interface AvailabilityRule {
  id: number
  weekday: number
  start_time: string
  end_time: string
  is_active: boolean
}

export interface ReservationSettings {
  slot_minutes: number
  min_notice_hours: number
  max_advance_days: number
}

export interface ReservationSettingsPayload {
  settings: ReservationSettings
  rules: AvailabilityRule[]
}

export async function fetchReservationSettings(): Promise<ReservationSettingsPayload> {
  const { data } = await api.get<ReservationSettingsPayload>('/lab/reservation-settings')
  return data
}

export async function updateReservationSettings(
  payload: ReservationSettingsPayload,
): Promise<ReservationSettingsPayload> {
  const { data } = await api.put<ReservationSettingsPayload>('/lab/reservation-settings', payload)
  return data
}

function toFormData(input: Record<string, unknown>): FormData {
  const formData = new FormData()
  Object.entries(input).forEach(([key, value]) => {
    if (value === undefined || value === null) return
    if (value instanceof File) {
      formData.append(key, value)
    } else if (typeof value === 'boolean') {
      formData.append(key, value ? 'true' : 'false')
    } else if (typeof value === 'object') {
      formData.append(key, JSON.stringify(value))
    } else {
      formData.append(key, String(value))
    }
  })
  return formData
}

export interface Announcement {
  id: number
  title: string
  body: string
  cover_image: string | null
  is_published: boolean
  published_at: string | null
  created_at: string
  updated_at: string
}

export interface AnnouncementInput {
  title: string
  body: string
  is_published: boolean
  published_at: string | null
  cover_image?: File | null
}

export async function fetchAnnouncements(): Promise<Announcement[]> {
  const { data } = await api.get<Announcement[]>('/lab/announcements')
  return data
}

export async function createAnnouncement(input: AnnouncementInput): Promise<Announcement> {
  const { data } = await api.post<Announcement>('/lab/announcements', toFormData(input))
  return data
}

export async function updateAnnouncement(id: number, input: AnnouncementInput): Promise<Announcement> {
  const { data } = await api.patch<Announcement>(`/lab/announcements/${id}`, toFormData(input))
  return data
}

export async function deleteAnnouncement(id: number): Promise<void> {
  await api.delete(`/lab/announcements/${id}`)
}

export interface SiteText {
  id: number
  key: string
  value: string
  updated_at: string
}

export async function fetchSiteTexts(): Promise<SiteText[]> {
  const { data } = await api.get<SiteText[]>('/lab/site-texts')
  return data
}

export async function updateSiteText(key: string, value: string): Promise<SiteText> {
  const { data } = await api.patch<SiteText>(`/lab/site-texts/${encodeURIComponent(key)}`, { value })
  return data
}

export type ContentSection =
  | 'home_stats'
  | 'home_skills'
  | 'services'
  | 'portfolio'
  | 'profile_values'
  | 'profile_career'
  | 'profile_apps'
  | 'profile_skills'

export const CONTENT_SECTION_OPTIONS: { key: ContentSection; label: string }[] = [
  { key: 'home_stats', label: 'ホーム: 実績数値' },
  { key: 'home_skills', label: 'ホーム: 技術スタック' },
  { key: 'services', label: 'サービス一覧' },
  { key: 'portfolio', label: '実績・ポートフォリオ' },
  { key: 'profile_values', label: 'プロフィール: こんな人です' },
  { key: 'profile_career', label: 'プロフィール: キャリア' },
  { key: 'profile_apps', label: 'プロフィール: 制作アプリ' },
  { key: 'profile_skills', label: 'プロフィール: 技術スタック' },
]

export interface ContentItem {
  id: number
  section: ContentSection
  order: number
  is_active: boolean
  image: string | null
  image_secondary: string | null
  data: Record<string, any>
  created_at: string
  updated_at: string
}

export interface ContentItemInput {
  section: ContentSection
  order: number
  is_active: boolean
  data: Record<string, any>
  image?: File | null
  image_secondary?: File | null
}

export async function fetchContentItems(section: ContentSection): Promise<ContentItem[]> {
  const { data } = await api.get<ContentItem[]>('/lab/content-items', { params: { section } })
  return data
}

export async function createContentItem(input: ContentItemInput): Promise<ContentItem> {
  const { data } = await api.post<ContentItem>('/lab/content-items', toFormData(input))
  return data
}

export async function updateContentItem(id: number, input: ContentItemInput): Promise<ContentItem> {
  const { data } = await api.patch<ContentItem>(`/lab/content-items/${id}`, toFormData(input))
  return data
}

export async function deleteContentItem(id: number): Promise<void> {
  await api.delete(`/lab/content-items/${id}`)
}

// --- 公開サイト用（認証不要） ---

export async function fetchPublicAnnouncements(limit?: number): Promise<Announcement[]> {
  const { data } = await api.get<Announcement[]>('/announcements', { params: limit ? { limit } : undefined })
  return data
}

export async function fetchPublicAnnouncement(id: number): Promise<Announcement> {
  const { data } = await api.get<Announcement>(`/announcements/${id}`)
  return data
}

export interface SiteContentResponse {
  texts: Record<string, string>
  items: Partial<Record<ContentSection, ContentItem[]>>
}

export async function fetchSiteContent(): Promise<SiteContentResponse> {
  const { data } = await api.get<SiteContentResponse>('/site-content')
  return data
}
