/** Lab の日記・メモ・タスクで使う画像圧縮とクリップボード取り込み。 */

export async function compressImage(file: File): Promise<File> {
  try {
    const bitmap = await createImageBitmap(file)
    const maxEdge = 1600
    const scale = Math.min(1, maxEdge / Math.max(bitmap.width, bitmap.height))
    const width = Math.max(1, Math.round(bitmap.width * scale))
    const height = Math.max(1, Math.round(bitmap.height * scale))
    const canvas = document.createElement('canvas')
    canvas.width = width
    canvas.height = height
    const ctx = canvas.getContext('2d')
    if (!ctx) return file
    ctx.drawImage(bitmap, 0, 0, width, height)
    bitmap.close()
    const blob = await new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, 'image/jpeg', 0.72))
    if (!blob) return file
    const base = file.name.replace(/\.[^.]+$/, '') || `paste-${Date.now()}`
    return new File([blob], `${base}.jpg`, { type: 'image/jpeg' })
  } catch {
    return file
  }
}

/** Ctrl+V などでクリップボードに入っている画像ファイルを取り出す。 */
export function filesFromClipboard(event: ClipboardEvent): File[] {
  const files: File[] = []
  const items = event.clipboardData?.items
  if (items) {
    for (const item of Array.from(items)) {
      if (!item.type.startsWith('image/')) continue
      const file = item.getAsFile()
      if (file) files.push(normalizePasteFile(file))
    }
  }
  if (!files.length && event.clipboardData?.files?.length) {
    for (const file of Array.from(event.clipboardData.files)) {
      if (file.type.startsWith('image/')) files.push(normalizePasteFile(file))
    }
  }
  return files
}

function normalizePasteFile(file: File): File {
  if (file.name && file.name !== 'image.png' && file.name !== 'image.jpg') return file
  const ext = file.type === 'image/png' ? 'png' : 'jpg'
  return new File([file], `paste-${Date.now()}.${ext}`, { type: file.type || 'image/jpeg' })
}
