import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

/**
 * Lab で編集できる URL をリンクに使う前に確かめる。http(s)・mailto とサイト内の相対パスだけを通し、
 * それ以外（javascript: など）は undefined にしてリンクを出さない。
 */
export function safeUrl(url: unknown): string | undefined {
  if (typeof url !== 'string') return undefined
  const value = url.trim()
  if (!value) return undefined
  if (value.startsWith('/') && !value.startsWith('//')) return value
  return /^(https?:\/\/|mailto:)/i.test(value) ? value : undefined
}
