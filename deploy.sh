#!/bin/bash

# ミツモア風アプリ Firebase デプロイメントスクリプト

echo "🔥 Firebase デプロイメント開始..."

# Firebase CLI がインストールされているかチェック
if ! command -v firebase &> /dev/null; then
    echo "Firebase CLI がインストールされていません。インストールしています..."
    npm install -g firebase-tools
fi

# Firebase にログイン
echo "Firebase にログイン中..."
firebase login

# プロジェクトを設定
echo "Firebase プロジェクトを設定中..."
firebase use mitsumore-app-80c1f

# Flutter Web ビルド
echo "Flutter Web アプリをビルド中..."
flutter build web

# Firestore ルールをデプロイ
echo "Firestore セキュリティルールをデプロイ中..."
firebase deploy --only firestore:rules

# Storage ルールをデプロイ
echo "Storage セキュリティルールをデプロイ中..."
firebase deploy --only storage

# Firestore インデックスをデプロイ
echo "Firestore インデックスをデプロイ中..."
firebase deploy --only firestore:indexes

# Web アプリをホスティングにデプロイ
echo "Web アプリをデプロイ中..."
firebase deploy --only hosting

echo "✅ デプロイメント完了！"
echo "🌐 アプリURL: https://mitsumore-app-80c1f.web.app" 