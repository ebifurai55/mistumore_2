# 🔥 Firebase セットアップガイド

## 1. Firebase Console でのプロジェクト作成

### Step 1: Firebase Console にアクセス
1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. 「プロジェクトを作成」をクリック
3. プロジェクト名: `mitsumore-app` (または任意の名前)
4. Google Analytics を有効にする (推奨)

### Step 2: Authentication 設定
1. 左メニューから「Authentication」を選択
2. 「始める」をクリック
3. 「Sign-in method」タブを選択
4. 「メール/パスワード」を有効にする
5. 必要に応じて他の認証方法も設定

### Step 3: Firestore Database 設定
1. 左メニューから「Firestore Database」を選択
2. 「データベースの作成」をクリック
3. **テストモード**で開始 (後でルールを変更)
4. ロケーション: `asia-northeast1` (東京) を選択

### Step 4: Storage 設定
1. 左メニューから「Storage」を選択
2. 「始める」をクリック
3. **テストモード**で開始 (後でルールを変更)
4. ロケーション: `asia-northeast1` (東京) を選択

### Step 5: Web アプリの追加
1. プロジェクト概要から「ウェブ」アイコンをクリック
2. アプリ名: `mitsumore-web`
3. 「Firebase Hosting も設定する」にチェック (任意)
4. 「アプリを登録」をクリック
5. **設定オブジェクトをコピー** (次のステップで使用)

## 2. 設定ファイルの更新

生成された設定を `lib/firebase_options.dart` に設定してください。

## 3. Firestore セキュリティルール

プロダクション環境では、適切なセキュリティルールを設定してください。

## 4. Storage セキュリティルール

画像アップロード用のセキュリティルールを設定してください。

## 5. テストユーザーの作成

アプリテスト用のユーザーアカウントを作成してください：
- 依頼者用: `client@test.com`
- 専門家用: `professional@test.com` 