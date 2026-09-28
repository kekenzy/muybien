import os

from django.conf import settings

# 日記写真の保存先。AWS_S3_DIARY_BUCKET があれば S3、無ければ MEDIA_ROOT。
# 本番コンテナは Lightsail のインスタンスロール（IMDSv2）で認証する。


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
            ExpiresIn=60 * 60 * 24 * 7,
        )
    rel = settings.MEDIA_URL + key
    if request is not None:
        return request.build_absolute_uri(rel)
    return rel
