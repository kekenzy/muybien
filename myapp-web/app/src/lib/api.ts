import axios from 'axios'
import { clearTokens, getAccessToken, getRefreshToken, setTokens } from './auth'

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
}

export interface LoginResponse {
  access: string
  refresh: string
}

export interface MeResponse {
  username: string
  email: string
  is_staff: boolean
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
}
