<template>
  <div>
    <!-- Hero -->
    <section class="relative py-20 sm:py-32 px-4 sm:px-6 bg-[#080c14] overflow-hidden">
      <div class="absolute inset-0 bg-[linear-gradient(to_right,#ffffff08_1px,transparent_1px),linear-gradient(to_bottom,#ffffff08_1px,transparent_1px)] bg-[size:48px_48px]" />
      <div class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[500px] h-[500px] bg-blue-600/15 rounded-full blur-[120px] pointer-events-none" />

      <div class="relative max-w-4xl mx-auto">
        <span class="text-xs font-semibold tracking-widest text-primary uppercase">Profile</span>
        <h1 class="text-4xl sm:text-5xl md:text-7xl font-black text-white mt-4 mb-6 leading-tight">
          永井 謙史
        </h1>
        <p class="text-white/50 text-base sm:text-lg md:text-xl max-w-xl leading-relaxed">
          AI × Django × AWS で、アイデアを最速でプロダクトに変えるFDE(Forward Deployed Engineer)。ITの力をより身近に。
        </p>
        <a
          href="https://kenzy-goldentime.blogspot.com/"
          target="_blank"
          rel="noopener noreferrer"
          class="inline-flex items-center gap-2 mt-8 text-sm text-white/50 hover:text-white transition-colors"
        >
          📝 Fly Away（ブログ） →
        </a>
      </div>
    </section>

    <!-- About -->
    <section class="py-24 px-6 bg-white">
      <div class="max-w-4xl mx-auto">
        <div class="text-center mb-16">
          <span class="text-xs font-semibold tracking-widest text-primary uppercase">About</span>
          <h2 class="text-3xl font-bold mt-2 text-gray-900">こんな人です</h2>
        </div>

        <div class="grid md:grid-cols-3 gap-6">
          <div
            v-for="item in values"
            :key="item.title"
            class="p-8 rounded-2xl border border-gray-100 hover:border-primary/30 hover:shadow-md transition-all"
          >
            <div class="text-3xl mb-4">{{ item.emoji }}</div>
            <div class="font-semibold text-gray-900 mb-2">{{ item.title }}</div>
            <div class="text-sm text-gray-500 leading-relaxed">{{ item.desc }}</div>
          </div>
        </div>
      </div>
    </section>

    <!-- Career -->
    <section class="py-24 px-6 bg-gray-50">
      <div class="max-w-3xl mx-auto">
        <div class="text-center mb-16">
          <span class="text-xs font-semibold tracking-widest text-primary uppercase">Career</span>
          <h2 class="text-3xl font-bold mt-2 text-gray-900">キャリア</h2>
        </div>

        <div class="relative pl-6 sm:pl-8 border-l-2 border-gray-200 space-y-10 sm:space-y-12">
          <div v-for="item in career" :key="item.year" class="relative">
            <div class="absolute -left-[1.65rem] sm:-left-[2.35rem] w-3.5 h-3.5 sm:w-4 sm:h-4 bg-primary rounded-full border-4 border-white shadow" />
            <div class="text-xs font-semibold text-primary mb-1">{{ item.year }}</div>
            <div class="font-bold text-gray-900 text-lg mb-1">{{ item.company }}</div>
            <div class="text-sm text-gray-500 leading-relaxed mb-4">{{ item.desc }}</div>
            <div class="flex flex-wrap gap-2">
              <span
                v-for="proj in item.projects"
                :key="proj"
                class="text-xs px-3 py-1 rounded-full bg-white border border-gray-200 text-gray-600"
              >{{ proj }}</span>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Apps -->
    <section class="py-24 px-6 bg-white">
      <div class="max-w-4xl mx-auto">
        <div class="text-center mb-16">
          <span class="text-xs font-semibold tracking-widest text-primary uppercase">Apps</span>
          <h2 class="text-3xl font-bold mt-2 text-gray-900">制作アプリ</h2>
        </div>

        <div class="grid md:grid-cols-2 gap-6">
          <div
            v-for="app in apps"
            :key="app.title"
            class="flex flex-col p-8 rounded-2xl border border-gray-100 hover:border-primary/30 hover:shadow-md transition-all"
          >
            <div class="flex items-center justify-between mb-4">
              <span class="text-xs font-semibold text-primary bg-blue-50 px-3 py-1 rounded-full">{{ app.category }}</span>
              <span class="text-xs text-gray-400">{{ app.date }}</span>
            </div>
            <div class="mb-2">
              <img
                v-if="app.icon"
                :src="app.icon"
                :alt="app.title"
                class="h-12 w-auto object-contain rounded-xl"
              />
              <span v-else class="text-2xl">{{ app.emoji }}</span>
            </div>
            <h3 class="font-semibold text-lg text-gray-900 mb-2">{{ app.title }}</h3>
            <p class="text-sm text-gray-500 leading-relaxed">{{ app.desc }}</p>
            <img
              v-if="app.screenshot"
              :src="app.screenshot"
              :alt="`${app.title}のゲーム画面`"
              class="mt-4 w-full rounded-xl border border-gray-100"
            />
            <div class="flex-1" />
            <div class="flex flex-wrap gap-2 mt-4">
              <span
                v-for="tag in app.tags"
                :key="tag"
                class="text-xs px-2 py-1 rounded-full bg-gray-50 text-gray-500 border border-gray-100"
              >{{ tag }}</span>
            </div>
            <a
              v-if="app.url"
              :href="app.url"
              target="_blank"
              rel="noopener noreferrer"
              class="mt-4 inline-flex items-center gap-1 text-xs text-primary hover:underline"
            >
              アプリ詳細を見る →
            </a>
          </div>
        </div>
      </div>
    </section>

    <!-- Skills -->
    <section class="py-24 px-6 bg-white">
      <div class="max-w-4xl mx-auto">
        <div class="text-center mb-16">
          <span class="text-xs font-semibold tracking-widest text-primary uppercase">Skills</span>
          <h2 class="text-3xl font-bold mt-2 text-gray-900">技術スタック</h2>
        </div>

        <div class="space-y-10">
          <div v-for="group in skillGroups" :key="group.label">
            <div class="text-xs font-semibold text-gray-400 tracking-widest uppercase mb-3">{{ group.label }}</div>
            <div class="flex flex-wrap gap-2">
              <span
                v-for="skill in group.items"
                :key="skill"
                class="px-4 py-2 rounded-full border text-sm transition-colors"
                :class="group.primary
                  ? 'border-primary/30 text-primary bg-blue-50 hover:bg-primary hover:text-white'
                  : 'border-gray-200 text-gray-500 hover:border-gray-400'"
              >
                {{ skill }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- CTA -->
    <section class="py-24 px-6 bg-[#080c14]">
      <div class="max-w-2xl mx-auto text-center">
        <h2 class="text-3xl sm:text-4xl font-black text-white mb-6 leading-tight">
          一緒に何か<br>つくりませんか？
        </h2>
        <p class="text-white/40 mb-10">初回相談は無料。気軽にメッセージください。</p>
        <router-link
          to="/contact"
          class="inline-flex items-center gap-2 bg-white text-gray-900 px-8 py-4 rounded-full font-semibold text-sm hover:bg-gray-100 transition-colors"
        >
          お問い合わせ →
        </router-link>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
const values = [
  {
    emoji: '🚀',
    title: '新規立ち上げが好き',
    desc: '0→1フェーズが特に好き。アイデアをプロダクトに変える瞬間にエネルギーを感じます。',
  },
  {
    emoji: '🤝',
    title: '顧客主語で動く',
    desc: 'ユーザーや顧客が何を必要としているかを軸に考える。技術はあくまで手段。',
  },
  {
    emoji: '⚡',
    title: '効率を極める',
    desc: 'AI × ツール活用で開発速度を最大化。繰り返し作業を自動化するのが好きです。',
  },
]

const career = [
  {
    year: '2000〜2004',
    company: 'エコーシステムズ',
    desc: '携帯電話テスターからキャリアをスタート。東京支店開設に伴い上京。Java / C++ を用いた Web・バッチシステム開発を担当。',
    projects: ['HIS（旅行）', '読売新聞', '松井証券', '携帯電話テスト', 'Java', 'C++'],
  },
  {
    year: '2004〜2021',
    company: 'キヤノンITソリューションズ（旧キヤノンソフトウェア）',
    desc: '組み込み・Web・モバイルと幅広い領域で17年間開発に従事。複合機・ロボット・プロジェクタ・ECU計測器など多様なドメインを経験。キャリア中盤で初代 Android を購入したことをきっかけに趣味のゲーム開発も開始。',
    projects: [
      'キヤノン複合機制御', 'キヤノン内製ロボット', 'プロジェクタ iOS/Android',
      'SUBARU ECU計測器', '楽天証券 Web', '京セラ 燃料電池',
      'KEYENCE Windows アプリ', 'ミネベアミツミ 受発注システム',
      'C / C++', 'Java', 'C#', 'Swift', 'Android',
    ],
  },
  {
    year: '2021〜現在',
    company: 'Globalway — PF事業部ディレクター',
    desc: 'Python / Django へ転向し Web サービス開発に専念。複数の大手 通信会社系案件を担当しながら、AI 活用・クラウドインフラ・チームマネジメントも推進。ディレクタとして新規顧客開拓を牽引。',
    projects: [
      '某大手通信会社 トラフィックレポート', '某大手通信会社マイページ',
      '個別指導塾',
      'Python / Django', 'AWS', 'AI活用推進',
    ],
  },
]

const apps = [
  {
    icon: '/images/yomohiro-kan-icon.png',
    title: '東西南北（よもひろ）館',
    category: '予約・決済',
    date: '2023年',
    desc: '旅館向けオンライン予約・決済システム。Square API 連携でクレジット決済に対応し、SMS通知・キャンセル自動処理・売上レポートを実装。Django + AWS で本番運用中。',
    screenshot: '/images/yomohiro-kan-screenshot.png',
    tags: ['Django', 'Square API', 'AWS Lightsail', 'PostgreSQL', 'SMS通知'],
    url: 'https://yomohirokan.com/',
  },
  {
    icon: '/images/monster-sweeper-icon.png',
    title: 'モンスタースイーパー',
    category: 'パズルゲーム',
    date: '2016年3月',
    desc: '罠をしかけてモンスターを倒す、新感覚マインスイーパーRPG。ダジャモン（ダジャレモンスター）を探し出して図鑑コンプリートを目指す。STELLA STUDIO として個人開発・リリース。',
    screenshot: '/images/monster-sweeper-screenshot.png',
    tags: ['Android', 'マインスイーパー', 'RPG', '個人開発'],
    url: 'https://appget.com/appli/view/62986/',
  },
]

const skillGroups = [
  {
    label: 'Backend',
    primary: true,
    items: ['Python', 'Django', 'Django REST Framework', 'PostgreSQL', 'Square API'],
  },
  {
    label: 'Frontend',
    primary: true,
    items: ['Vue 3', 'TypeScript', 'Tailwind CSS', 'Vite'],
  },
  {
    label: 'Cloud / Infra',
    primary: false,
    items: ['AWS Lightsail', 'AWS SES', 'AWS S3', 'Docker', 'Nginx', 'Linux'],
  },
  {
    label: 'AI',
    primary: false,
    items: ['Claude API', 'GPT-4', 'RAG', 'プロンプト設計', 'Cursor IDE', 'AI駆動開発'],
  },
  {
    label: 'Past Experience',
    primary: false,
    items: ['Java', 'C', 'C++', 'C#', 'Swift', 'Android', 'iOS', 'Raspberry Pi', 'Chart.js'],
  },
]
</script>
