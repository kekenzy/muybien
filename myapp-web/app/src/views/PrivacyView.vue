<template>
  <section class="py-16 sm:py-24 px-4 sm:px-6">
    <article class="max-w-3xl mx-auto">
      <header class="mb-10 sm:mb-12">
        <span class="text-xs font-semibold tracking-widest text-primary uppercase">Privacy Policy</span>
        <h1 class="text-2xl sm:text-3xl font-bold mt-2">プライバシーポリシー</h1>
        <p class="text-sm text-gray-600 mt-6 leading-relaxed">
          {{ OPERATOR_NAME }}（以下「運営者」といいます）は、ウェブサイト「MuyBien」（https://muybien.jp/。以下「本サイト」といいます）で取得する個人情報を、個人情報の保護に関する法律（以下「個人情報保護法」といいます）その他の法令に従い、次のとおり取り扱います。
        </p>
      </header>

      <div class="space-y-10 text-sm text-gray-700 leading-relaxed">
        <section>
          <h2 class="text-lg font-bold text-gray-900 mb-3">1. 事業者の名称・住所・代表者</h2>
          <dl class="grid grid-cols-[6.5rem_1fr] gap-x-4 gap-y-2">
            <dt class="text-gray-500">名称</dt>
            <dd>{{ OPERATOR_NAME }}</dd>
            <dt class="text-gray-500">代表者</dt>
            <dd>{{ REPRESENTATIVE }}</dd>
            <dt class="text-gray-500">住所</dt>
            <dd>ご請求があった場合に、遅滞なくお知らせします（第9項の窓口までご連絡ください）。</dd>
          </dl>
        </section>

        <section>
          <h2 class="text-lg font-bold text-gray-900 mb-3">2. 取得する情報</h2>
          <p class="mb-3">運営者は、次の情報を取得します。</p>
          <ul class="list-disc pl-5 space-y-2">
            <li>
              <span class="font-medium text-gray-900">お問い合わせフォーム</span>：お名前、メールアドレス、件名、メッセージ本文、送信日時
            </li>
            <li>
              <span class="font-medium text-gray-900">顧客ポータル（運営者からご案内したお客様のみ）</span>：氏名、メールアドレス、電話番号、会社名、ご予約の日時・備考、ログイン用のパスワード（暗号学的に変換して保存し、運営者も元のパスワードは分かりません）
            </li>
            <li>
              <span class="font-medium text-gray-900">お支払い情報</span>：クレジットカード情報は決済代行会社 Stripe が直接取得し、運営者のサーバーには保存しません。運営者はカードのブランド・下4桁・有効期限など、Stripe から返される表示用の情報だけを扱います。
            </li>
            <li>
              <span class="font-medium text-gray-900">アクセス時に自動で送信される情報</span>：IPアドレス、ブラウザの種類（ユーザーエージェント）、アクセス日時、閲覧したURLなど。サーバーのログとして記録します。
            </li>
          </ul>
        </section>

        <section>
          <h2 class="text-lg font-bold text-gray-900 mb-3">3. 利用目的</h2>
          <ul class="list-disc pl-5 space-y-2">
            <li>お問い合わせ・ご相談への回答、ご連絡のため</li>
            <li>ご依頼いただいた業務の提供、ご予約の管理、料金のお支払い手続きのため</li>
            <li>顧客ポータルへのログイン、パスワード設定・再設定のご案内メールの送信のため</li>
            <li>不正アクセスの防止、障害の調査など、本サイトを安全に運営するため</li>
          </ul>
          <p class="mt-3">上記の目的以外に利用する場合は、あらかじめご本人の同意を得ます。</p>
        </section>

        <section>
          <h2 class="text-lg font-bold text-gray-900 mb-3">4. 第三者への提供</h2>
          <p>
            運営者は、法令に基づく場合を除き、ご本人の同意を得ずに個人情報を第三者へ提供しません。次項の委託先への預け入れは、ここでいう第三者への提供にあたりません。
          </p>
        </section>

        <section>
          <h2 class="text-lg font-bold text-gray-900 mb-3">5. 業務の委託（外部サービスの利用）</h2>
          <p class="mb-4">
            運営者は、利用目的の達成に必要な範囲で、個人情報の取り扱いを次の事業者に委託しています。委託先は、個人情報を適切に取り扱う体制を整えた事業者を選び、必要な監督を行います。
          </p>
          <div class="overflow-x-auto">
            <table class="min-w-[32rem] w-full text-left border-collapse">
              <thead>
                <tr class="border-b border-gray-200 text-gray-500">
                  <th class="py-2 pr-4 font-medium">委託先</th>
                  <th class="py-2 pr-4 font-medium">委託する内容</th>
                  <th class="py-2 font-medium">データの所在国</th>
                </tr>
              </thead>
              <tbody>
                <tr class="border-b border-gray-100 align-top">
                  <td class="py-3 pr-4">Amazon Web Services, Inc.（Amazon Lightsail・Amazon S3）</td>
                  <td class="py-3 pr-4">本サイトのサーバー・データベース・ファイルの保管</td>
                  <td class="py-3">日本（東京リージョン）</td>
                </tr>
                <tr class="border-b border-gray-100 align-top">
                  <td class="py-3 pr-4">Amazon Web Services, Inc.（Amazon SES）</td>
                  <td class="py-3 pr-4">お問い合わせの受付通知・各種ご案内メールの送信</td>
                  <td class="py-3">日本（東京リージョン）</td>
                </tr>
                <tr class="border-b border-gray-100 align-top">
                  <td class="py-3 pr-4">Stripe, Inc.</td>
                  <td class="py-3 pr-4">クレジットカード決済（氏名・メールアドレスを顧客情報として登録します）</td>
                  <td class="py-3">アメリカ合衆国</td>
                </tr>
              </tbody>
            </table>
          </div>
          <p class="mt-4">
            Stripe, Inc. はアメリカ合衆国の事業者です。同国の個人情報保護制度については、個人情報保護委員会が公表している
            <a
              href="https://www.ppc.go.jp/personalinfo/legal/kaiseihogohou/"
              target="_blank"
              rel="noopener noreferrer"
              class="text-primary underline underline-offset-2 hover:opacity-80"
            >外国の個人情報の保護に関する制度</a>
            の情報をご確認ください。Stripe は、個人情報保護法の定める義務に相当する措置を継続して講じるための体制を整えています。
          </p>
        </section>

        <section>
          <h2 class="text-lg font-bold text-gray-900 mb-3">6. 外部への情報送信（フォントの読み込み）</h2>
          <p class="mb-3">
            本サイトは、文字の表示に Google Fonts を使っています。ページを開くと、お使いのブラウザから次の情報が Google に送信されます。
          </p>
          <dl class="grid grid-cols-[6.5rem_1fr] gap-x-4 gap-y-2">
            <dt class="text-gray-500">送信先</dt>
            <dd>Google LLC（Google Fonts）</dd>
            <dt class="text-gray-500">送信される情報</dt>
            <dd>IPアドレス、ブラウザの種類（ユーザーエージェント）、閲覧中のページのURL</dd>
            <dt class="text-gray-500">利用目的</dt>
            <dd>フォントファイルの配信のため</dd>
            <dt class="text-gray-500">詳しくは</dt>
            <dd>
              <a
                href="https://policies.google.com/privacy?hl=ja"
                target="_blank"
                rel="noopener noreferrer"
                class="text-primary underline underline-offset-2 hover:opacity-80"
              >Google プライバシーポリシー</a>
            </dd>
          </dl>
          <p class="mt-3">本サイトは、アクセス解析ツールや広告のための Cookie を使っていません。</p>
        </section>

        <section>
          <h2 class="text-lg font-bold text-gray-900 mb-3">7. 安全管理のために講じた措置</h2>
          <p class="mb-3">運営者は、個人情報の漏えい・滅失・毀損を防ぐため、次の措置を講じています。</p>
          <ul class="list-disc pl-5 space-y-2">
            <li><span class="font-medium text-gray-900">基本方針・規律</span>：本ポリシーを定め、取得・利用・保存・削除の各段階での取り扱い方法を決めています。</li>
            <li><span class="font-medium text-gray-900">組織的な措置</span>：個人情報を取り扱うのは運営者本人に限っています。漏えいなどが起きた場合は、法令に従い個人情報保護委員会への報告とご本人への通知を行います。</li>
            <li><span class="font-medium text-gray-900">人的な措置</span>：運営者は、個人情報の取り扱いについて継続して確認・学習しています。</li>
            <li><span class="font-medium text-gray-900">物理的な措置</span>：データは物理的な安全対策がとられたクラウド事業者のデータセンターに保管し、業務で使う端末には画面ロックを設定し、端末と記録媒体のディスクを暗号化しています。</li>
            <li><span class="font-medium text-gray-900">技術的な措置</span>：通信を暗号化（HTTPS）し、管理画面はログインした権限のある者だけが使えるようにしています。サーバーや外部サービスなど、管理に使うアカウントには2段階認証を設定しています。パスワードは暗号学的に変換して保存し、ログインの試行回数を制限しています。</li>
            <li><span class="font-medium text-gray-900">外的環境の把握</span>：データは原則として日本国内（AWS 東京リージョン）に保管しています。アメリカ合衆国の Stripe, Inc. に預ける情報については、同国の個人情報保護制度を把握したうえで安全管理措置を講じています。</li>
          </ul>
        </section>

        <section>
          <h2 class="text-lg font-bold text-gray-900 mb-3">8. 保有個人データの開示などの請求</h2>
          <p class="mb-3">
            ご本人は、運営者が保有する個人データについて、利用目的の通知、開示、訂正・追加・削除、利用の停止・消去、第三者提供の停止、第三者提供記録の開示を請求できます。
          </p>
          <p>
            次項の窓口までご連絡ください。ご本人（または代理人）であることを確認したうえで、法令に従い遅滞なく対応します。手数料はいただきません。
          </p>
        </section>

        <section>
          <h2 class="text-lg font-bold text-gray-900 mb-3">9. お問い合わせ窓口</h2>
          <p>
            個人情報の取り扱いに関するご質問・苦情・開示などの請求は、下記のメールアドレス、または
            <router-link to="/contact" class="text-primary underline underline-offset-2 hover:opacity-80">お問い合わせフォーム</router-link>
            から、件名に「個人情報について」とご記入のうえご連絡ください。
          </p>
          <dl class="grid grid-cols-[6.5rem_1fr] gap-x-4 gap-y-2 mt-3">
            <dt class="text-gray-500">窓口</dt>
            <dd>{{ OPERATOR_NAME }}　個人情報お問い合わせ窓口</dd>
            <dt class="text-gray-500">メール</dt>
            <dd class="break-all">{{ CONTACT_EMAIL }}</dd>
          </dl>
        </section>

        <section>
          <h2 class="text-lg font-bold text-gray-900 mb-3">10. 本ポリシーの変更</h2>
          <p>
            運営者は、法令の改正や本サイトの変更に合わせて本ポリシーを改定することがあります。重要な変更がある場合は、本サイト上でお知らせします。改定後の内容は、本ページに掲載した時点から効力を生じます。
          </p>
        </section>

        <p class="pt-6 border-t border-gray-100 text-right text-gray-500">
          制定日：{{ ESTABLISHED_ON }}
        </p>
      </div>
    </article>
  </section>
</template>

<script setup lang="ts">
// 運営者は屋号 Stella Studio・代表者 永井 謙史（全プロジェクト共通）
const OPERATOR_NAME = 'Stella Studio'
const REPRESENTATIVE = '永井 謙史'
// 個人情報の窓口（Stella Studio 共通）
const CONTACT_EMAIL = 'stellastudio4xx＠gmail.com'
// 公開日に合わせて更新する。改定したら「最終改定日」を別に足す
const ESTABLISHED_ON = '2026年11月12日'
</script>
