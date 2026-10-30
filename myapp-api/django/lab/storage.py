import os
import re
from urllib.parse import quote

from django.conf import settings
from django.core import signing

# 日記写真の保存先。AWS_S3_DIARY_BUCKET があれば S3、無ければ MEDIA_ROOT。
# 本番コンテナは Lightsail のインスタンスロール（IMDSv2）で認証する。
# 写真は本人以外に見せないため、URL は短時間だけ有効な署名付きにする（/media/ では公開しない）。

PHOTO_URL_MAX_AGE = 60 * 60
_PHOTO_SALT = 'lab.photo'
_PHOTO_KEY_RE = re.compile(r'^(diary|memo|task)/\d+/[0-9a-f]{32}\.jpg$')


def diary_bucket():
    return os.environ.get('AWS_S3_DIARY_BUCKET', '').strip()


def diary_region():
    return os.environ.get('AWS_S3_REGION', 'ap-northeast-1')


def _s3():
    import boto3

    return boto3.client('s3', region_name=diary_region())


def save_bytes(key, data, content_type):
    bucket = diary_bucket()
    if bucket:
        _s3().put_object(Bucket=bucket, Key=key, Body=data, ContentType=content_type)
        return
    path = os.path.join(settings.MEDIA_ROOT, key)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as fh:
        fh.write(data)


def delete_bytes(key):
    if not key:
        return
    bucket = diary_bucket()
    if bucket:
        _s3().delete_object(Bucket=bucket, Key=key)
        return
    path = os.path.join(settings.MEDIA_ROOT, key)
    if os.path.isfile(path):
        os.remove(path)


def photo_url(key, request=None):
    bucket = diary_bucket()
    if bucket:
        return _s3().generate_presigned_url(
            'get_object',
            Params={'Bucket': bucket, 'Key': key},
            ExpiresIn=PHOTO_URL_MAX_AGE,
        )
    token = signing.TimestampSigner(salt=_PHOTO_SALT).sign(key)
    rel = f'/v1/api/lab/photos?t={quote(token)}'
    if request is not None:
        return request.build_absolute_uri(rel)
    return rel


def photo_path_from_token(token):
    """署名付きURLのトークンを検証し、写真ファイルのパスを返す。不正・期限切れなら None。"""
    try:
        key = signing.TimestampSigner(salt=_PHOTO_SALT).unsign(token, max_age=PHOTO_URL_MAX_AGE)
    except signing.BadSignature:
        return None
    if not _PHOTO_KEY_RE.match(key):
        return None
    path = os.path.join(settings.MEDIA_ROOT, key)
    return path if os.path.isfile(path) else None
