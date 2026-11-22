#!/usr/bin/env python3
"""サーバー側（Django の外）の異常・攻撃をメールで知らせる小さなスクリプト。

Django の core/alerts.py と同じ件名・同じ宛先・同じメール送信の設定（.env.prod の EMAIL_*）を使う。
標準ライブラリだけで動く（ホストの python3 と fail2ban コンテナの python3 の両方で使う）。

  ban   fail2ban が遮断したときに呼ぶ（deploy/fail2ban/action.d/muybien-alert.conf）
  tick  5分ごとに呼ぶ（systemd タイマー）。溜めた通知のまとめ送信と、サイトの死活確認
  test  テスト通知を1通送る

件名: [ALERT][MuyBienBase][dos|intrusion|error|down] 要約
"""
import argparse
import contextlib
import datetime
import fcntl
import json
import os
import smtplib
import socket
import ssl
import sys
import urllib.error
import urllib.request
from email.message import EmailMessage
from email.utils import formatdate, make_msgid

PROJECT = 'MuyBienBase'
KINDS = ('dos', 'intrusion', 'error', 'down')
DEFAULT_ENV_FILE = '/home/ec2-user/muybien/.env.prod'
DEFAULT_STATE_DIR = '/var/lib/muybien-alert'
PENDING_KEEP = 30
DOWN_AFTER_FAILURES = 2
JST = datetime.timezone(datetime.timedelta(hours=9), 'JST')


def now():
    return datetime.datetime.now(JST)


def load_env(path):
    env = {}
    with open(path, encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#') or '=' not in line:
                continue
            key, value = line.split('=', 1)
            value = value.strip()
            if len(value) >= 2 and value[0] == value[-1] and value[0] in '"\'':
                value = value[1:-1]
            env[key.strip()] = value
    return env


def truthy(value):
    return str(value).strip().lower() in ('1', 'true', 'yes')


class Notifier:
    def __init__(self, env, state_dir, dry_run=False):
        self.env = env
        self.state_dir = state_dir
        self.dry_run = dry_run
        self.to = env.get('ALERT_EMAIL', 'kekenzy@gmail.com').strip()
        self.cooldown = int(env.get('ALERT_COOLDOWN_SECONDS') or 15 * 60)
        self.server = env.get('ALERT_SERVER_NAME') or socket.gethostname()
        self.site = env.get('FRONTEND_BASE_URL', '')

    # --- 状態（JSON ファイル。fail2ban とタイマーが同時に触るのでロックする） ---
    @contextlib.contextmanager
    def state(self):
        os.makedirs(self.state_dir, exist_ok=True)
        path = os.path.join(self.state_dir, 'state.json')
        with open(os.path.join(self.state_dir, 'state.lock'), 'w') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            try:
                with open(path, encoding='utf-8') as f:
                    data = json.load(f)
            except (FileNotFoundError, ValueError):
                data = {}
            yield data
            tmp = path + '.tmp'
            with open(tmp, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False)
            os.replace(tmp, path)

    # --- 送信 ---
    def _smtp_send(self, subject, text):
        if self.dry_run:
            print(f'Subject: {subject}\nTo: {self.to}\n\n{text}')
            return
        host = self.env.get('EMAIL_HOST')
        if not host:
            raise RuntimeError('EMAIL_HOST が設定されていません')
        port = int(self.env.get('EMAIL_PORT') or 587)
        msg = EmailMessage()
        msg['Subject'] = subject
        msg['From'] = self.env.get('DEFAULT_FROM_EMAIL', 'no-reply@example.com')
        msg['To'] = self.to
        msg['Date'] = formatdate(localtime=True)
        msg['Message-ID'] = make_msgid()
        msg.set_content(text)
        context = ssl.create_default_context()
        if truthy(self.env.get('EMAIL_USE_SSL', 'False')):
            smtp = smtplib.SMTP_SSL(host, port, timeout=20, context=context)
        else:
            smtp = smtplib.SMTP(host, port, timeout=20)
        with smtp:
            if truthy(self.env.get('EMAIL_USE_TLS', 'True')) and not truthy(self.env.get('EMAIL_USE_SSL', 'False')):
                smtp.starttls(context=context)
            user = self.env.get('EMAIL_HOST_USER')
            if user:
                smtp.login(user, self.env.get('EMAIL_HOST_PASSWORD', ''))
            smtp.send_message(msg)

    def _compose(self, kind, body, pending):
        lines = [
            f'日時: {now():%Y-%m-%d %H:%M:%S %Z}',
            f'サーバー: {self.server}',
            f'サイト: {self.site}',
            f'種類: {kind}',
            '',
            body.rstrip(),
        ]
        if pending and pending.get('count'):
            lines += ['', f'--- 前回の通知のあと、間隔を空けるために送らなかった同じ種類の通知: {pending["count"]} 件 ---']
            lines += pending['items']
            if pending['count'] > len(pending['items']):
                lines.append(f'（ほか {pending["count"] - len(pending["items"])} 件は省略）')
        return '\n'.join(lines).rstrip() + '\n'

    def send(self, kind, summary, body, force=False):
        """同じ種類は cooldown 秒に1通。間の分は溜めて次に載せる。送ったら True。"""
        if kind not in KINDS:
            raise ValueError(kind)
        if not self.to:
            return False
        ts = now().timestamp()
        with self.state() as st:
            last = st.setdefault('last_sent', {}).get(kind, 0)
            pendings = st.setdefault('pending', {})
            if not force and ts - last < self.cooldown:
                p = pendings.setdefault(kind, {'count': 0, 'items': []})
                p['count'] += 1
                p['items'] = (p['items'] + [f'{now():%Y-%m-%d %H:%M:%S} {summary}'])[-PENDING_KEEP:]
                return False
            pending = pendings.pop(kind, None)
            st['last_sent'][kind] = ts
        try:
            self._smtp_send(f'[ALERT][{PROJECT}][{kind}] {summary}', self._compose(kind, body, pending))
        except Exception as e:
            print(f'アラートメールの送信に失敗しました: {type(e).__name__}: {e}', file=sys.stderr)
            with self.state() as st:
                if pending:
                    p = st.setdefault('pending', {}).setdefault(kind, {'count': 0, 'items': []})
                    p['count'] += pending['count']
                    p['items'] = (pending['items'] + p['items'])[-PENDING_KEEP:]
                st['last_sent'][kind] = last
            return False
        return True

    def flush(self):
        sent = []
        ts = now().timestamp()
        with self.state() as st:
            ready = [
                kind for kind, p in st.get('pending', {}).items()
                if p.get('count') and ts - st.get('last_sent', {}).get(kind, 0) >= self.cooldown
            ]
        for kind in ready:
            with self.state() as st:
                count = st['pending'][kind]['count']
            if self.send(kind, f'まとめ: {count} 件', '間隔を空けている間に起きた通知のまとめです。'):
                sent.append(kind)
        return sent


# --- サブコマンド ---

JAIL_TEXT = {
    'sshd': ('SSH', 'SSH へのログイン失敗'),
    'nginx-limit-req': ('nginx', 'nginx の回数制限（limit_req）に繰り返し当たるアクセス'),
    'muybien-auth': ('nginx', 'ログイン・パスワード再設定 API への失敗の繰り返し'),
}


def cmd_ban(n, args):
    where, what = JAIL_TEXT.get(args.jail, (args.jail, f'fail2ban の {args.jail} の検知'))
    hours = int(args.bantime) // 3600 if str(args.bantime).lstrip('-').isdigit() else args.bantime
    body = '\n'.join([
        f'何が: {what}',
        f'どこで: {where}（fail2ban の jail: {args.jail}）',
        f'回数: {args.failures} 回（検知の期間内）',
        f'アクセス元 IP: {args.ip}',
        f'自動でしたこと: この IP を {hours} 時間遮断しました（繰り返すと遮断時間が延びます）',
        f'解除するとき: sudo docker exec muybien-fail2ban fail2ban-client set {args.jail} unbanip {args.ip}',
    ])
    n.send(args.kind, f'{what}を遮断 {args.ip}（{args.failures}回）', body)


def check_health(n, url):
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'muybien-alert-healthcheck'})
        with urllib.request.urlopen(req, timeout=15) as res:
            return res.status < 500, f'HTTP {res.status}'
    except urllib.error.HTTPError as e:
        return e.code < 500, f'HTTP {e.code}'
    except Exception as e:
        return False, f'{type(e).__name__}: {e}'


def cmd_tick(n, args):
    url = n.env.get('ALERT_HEALTH_URL') or (n.site.rstrip('/') + '/v1/api/site-content' if n.site else '')
    if url and not args.skip_health:
        ok, detail = check_health(n, url)
        with n.state() as st:
            health = st.setdefault('health', {'failures': 0, 'down': False})
            health['failures'] = 0 if ok else health['failures'] + 1
            went_down = not ok and health['failures'] == DOWN_AFTER_FAILURES
            recovered = ok and health['down']
            if went_down:
                health['down'] = True
                health['since'] = f'{now():%Y-%m-%d %H:%M}'
            if recovered:
                since = health.get('since', '?')
                health['down'] = False
        if went_down:
            n.send('down', f'サイトに接続できません {url}', '\n'.join([
                f'何が: 死活確認（5分ごと）が {DOWN_AFTER_FAILURES} 回続けて失敗しました',
                f'URL: {url}',
                f'結果: {detail}',
                'アクセス元 IP: -（サーバー自身からの確認）',
                '自動でしたこと: なし。復旧したらもう1通送ります',
                '確認: ssh muy → sudo docker compose -f docker-compose.prod.yml ps / logs',
            ]), force=True)
        if recovered:
            n.send('down', f'復旧しました {url}', '\n'.join([
                f'何が: 死活確認が成功に戻りました（止まっていたのは {since} ごろから）',
                f'URL: {url}',
                f'結果: {detail}',
                '自動でしたこと: なし',
            ]), force=True)
    sent = n.flush()
    if sent:
        print('まとめて送った種類: ' + ', '.join(sent))


def cmd_test(n, args):
    ok = n.send(args.kind, 'テスト通知です（対応は不要です・サーバー側）', '\n'.join([
        '何が: サーバー側の通知（fail2ban・死活確認）の仕組みのテストです',
        'アクセス元 IP: -',
        '自動でしたこと: なし',
    ]), force=True)
    if not ok:
        sys.exit(1)
    print(f'テスト通知を {n.to} へ送りました')


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--env-file', default=os.environ.get('MUYBIEN_ENV_FILE', DEFAULT_ENV_FILE))
    parser.add_argument('--state-dir', default=os.environ.get('MUYBIEN_ALERT_STATE_DIR', DEFAULT_STATE_DIR))
    parser.add_argument('--dry-run', action='store_true', help='送らずに標準出力へ出す')
    sub = parser.add_subparsers(dest='command', required=True)

    p = sub.add_parser('ban')
    p.add_argument('--kind', choices=KINDS, default='intrusion')
    p.add_argument('--jail', required=True)
    p.add_argument('--ip', required=True)
    p.add_argument('--failures', default='?')
    p.add_argument('--bantime', default='?')
    p.set_defaults(func=cmd_ban)

    p = sub.add_parser('tick')
    p.add_argument('--skip-health', action='store_true')
    p.set_defaults(func=cmd_tick)

    p = sub.add_parser('test')
    p.add_argument('--kind', choices=KINDS, default='intrusion')
    p.set_defaults(func=cmd_test)

    args = parser.parse_args(argv)
    n = Notifier(load_env(args.env_file), args.state_dir, dry_run=args.dry_run)
    args.func(n, args)


if __name__ == '__main__':
    main()
