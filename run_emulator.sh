#!/bin/bash

# Firebase エミュレーター起動スクリプト
# 開発・テスト環境用

echo "🔥 Firebase エミュレーター起動中..."

# Firebase CLI がインストールされているかチェック
if ! command -v firebase &> /dev/null; then
    echo "Firebase CLI がインストールされていません。インストールしています..."
    npm install -g firebase-tools
fi

# プロジェクトを設定
firebase use mitsumore-app-80c1f

echo "📱 エミュレーター起動中..."
echo "🌐 Firebase UI: http://localhost:4000"
echo "🔐 Auth エミュレーター: http://localhost:9099"
echo "📊 Firestore エミュレーター: http://localhost:8080"
echo "🗂️ Storage エミュレーター: http://localhost:9199"
echo "🌍 Hosting エミュレーター: http://localhost:5000"
echo ""
echo "エミュレーターを停止するには Ctrl+C を押してください"

# エミュレーター起動
firebase emulators:start 