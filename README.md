# 📘 Reading Habit
 
**短時間の読書を、確実な習慣と成長につなげる読書支援アプリ**
 
アルバイトや授業で忙しい学生・社会人が、限られた時間の中でも読書を続け、内容を自分の言葉で定着させることを目的として個人開発しました。
 
---
 
## 🌐 デモ
 
> **[https://reading-habit-app.web.app](https://reading-habit-app.web.app)**（Firebase Hosting で公開中）
 
---
 
## 🎯 作った背景
 
読書をしても「読んだ気になって終わり」になりがちな経験から着想しました。
「時間がない」「内容を忘れる」「続かない」という3つの課題を、**短時間セッション × 読後リフレクション × 継続記録**の組み合わせで解決しようとしています。
 
| 課題 | アプローチ |
|------|-----------|
| まとまった時間が取れない | 読書タイマーで短いセッションを積み重ねる |
| 読んでも内容が定着しない | 読書直後にクイック・リフレクションを記録 |
| 一人では継続が難しい | 日別の学習時間を可視化し達成感を得られる設計 |
 
---
 
## ✨ 主な機能
 
- **本の登録・管理** — 読みたい本 / 読書中の本をカード形式で管理
- **読書タイマー** — セッション単位で読書時間を計測・記録
- **クイック・リフレクション** — 読書直後の気づき・学びを最小限の手間で入力
- **Google ログイン** — Firebase Authentication による認証
- **クラウド同期** — Cloud Firestore でデータを保存し、複数デバイスで参照可能
 
---
 
## 🛠 技術スタック
 
| カテゴリ | 技術 |
|----------|------|
| フレームワーク | Flutter（Dart） |
| 認証 | Firebase Authentication（Google サインイン） |
| データベース | Cloud Firestore |
| ホスティング | Firebase Hosting |
| 対応プラットフォーム | Web（iOS / Android 対応予定） |
 
> **選定理由:** 将来的なモバイル対応を見据え、Web・iOS・Android を1つのコードベースでカバーできる Flutter を採用しました。
 
---
 
## 📁 ディレクトリ構成
 
```
reading-habit-app/
├── lib/           # Dart ソースコード（画面・ロジック）
├── web/           # Web向けエントリポイント
├── android/       # Android プラットフォームコード
├── ios/           # iOS プラットフォームコード
├── test/          # テストコード
├── docs/          # スクリーンショット等のドキュメント
├── pubspec.yaml   # 依存パッケージ定義
└── README.md
```
 
---
 
## 🚀 ローカルでの起動方法
 
**前提:** Flutter SDK がインストール済みであること（[公式ドキュメント](https://docs.flutter.dev/get-started/install)）
 
```bash
# リポジトリをクローン
git clone https://github.com/nekomikandayo/reading-habit-app.git
cd reading-habit-app
 
# 依存パッケージを取得
flutter pub get
 
# Web で起動
flutter run -d chrome
```
 
---
 
## 🧩 設計で意識したこと
 
- **UI → ロジック → データの順で設計してから実装** に取り組み、後から仕様変更が発生した際の修正コストを抑えた
- Firebase の認証とデータ保存を組み合わせることで、**ログイン状態に連動したデータ管理**を実現
- 「リフレクションの入力が面倒」にならないよう、**最小限の操作で記録できる UX** を意識した
 
---
 
## 🏗 今後の予定
 
- [ ] 読書統計の可視化（週次・月次グラフ）
- [ ] 目標時間の設定と進捗表示
- [ ] iOS / Android ネイティブアプリのリリース
- [ ] AI によるリフレクションへのフィードバック機能
 
---
 
## 👤 Author
 
**森宗 伶太（Reita Morimune）**  
広島工業大学 情報コミュニケーション学科 2年  
[Portfolio](https://nekomikandayo.github.io/portfolio/) / [GitHub](https://github.com/nekomikandayo)
