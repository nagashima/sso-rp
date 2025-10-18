# Rails SSO Relying Party (RP) - Demo Application

**ORY Hydra IdP**と連携するシンプルなRelying Party（検証用アプリケーション）

## 🚀 クイックスタート

### 前提条件
1. **IdPが起動していること**
   - IdPプロジェクト（sso-idp）が起動している必要があります
   - `https://idp.localhost` が稼働中であることを確認

2. **/etc/hosts設定**
   ```bash
   sudo sh -c 'echo "127.0.0.1 idp.localhost" >> /etc/hosts'
   ```

### 初回セットアップ

#### 1. IdP側でOAuth2クライアント登録
IdPプロジェクトで以下のコマンドを実行：
```bash
cd /path/to/sso-idp
./scripts/register-client.sh "https://localhost:3443/auth/sso/callback" \
  --first-party \
  --cors-origin "https://idp.localhost,https://localhost:3443"
```

登録後、`CLIENT_ID`と`CLIENT_SECRET`が表示されます。

#### 2. RP側の環境設定
```bash
# .env.localを作成
cp .env.local.example .env.local

# .env.localを編集して、IdPで取得したクライアント情報を設定
# OAUTH_CLIENT_ID=<取得したCLIENT_ID>
# OAUTH_CLIENT_SECRET=<取得したCLIENT_SECRET>
```

#### 3. RPの起動
```bash
docker-compose up -d
```

### 動作確認
- **RP画面**: https://localhost:3443
- **SSOログイン**: https://localhost:3443 → "Login with SSO"ボタンをクリック

---

## 🏗️ アーキテクチャ

### サービス構成
```
┌─────────────────────┐
│   Browser           │
│                     │
└──────┬──────────────┘
       │ HTTPS
       │
       ├─────────────────────────────┐
       │                             │
       ▼                             ▼
┌─────────────────────┐    ┌─────────────────────┐
│   IdP (sso-idp)     │    │   RP (this app)     │
│  idp.localhost      │    │  localhost:3443     │
│    (port 443)       │    │    (port 3443)      │
└──────┬──────────────┘    └──────┬──────────────┘
       │                          │
       │   sso-network (Docker)   │
       └──────────────────────────┘
              内部通信
```

### 認証フロー
1. ユーザーがRPの「Login with SSO」をクリック
2. IdPの認証画面にリダイレクト（`https://idp.localhost`）
3. ユーザーがIdPでログイン・認証
4. 認証コードを持ってRPにリダイレクト
5. RPがトークン取得（内部通信: `idp-nginx-1:443`）
6. ユーザー情報取得・セッション確立

---

## 🔧 設定

### 環境変数（`.env` / `.env.local`）

#### `.env`（デフォルト設定、コミット対象）
基本設定とプレースホルダーが含まれています。

#### `.env.local`（個人設定、gitignore）
IdPで登録したOAuth2クライアント情報を設定：

```bash
# OAuth2クライアント情報（IdPで登録後に取得）
OAUTH_CLIENT_ID=your_actual_client_id
OAUTH_CLIENT_SECRET=your_actual_client_secret

# その他の設定は.envから継承されます
```

---

## 📝 開発コマンド

### Docker操作
```bash
# サービス起動
docker-compose up -d

# サービス停止
docker-compose down

# ログ確認
docker-compose logs -f

# コンテナ内シェル
docker-compose exec app bash
```

### Rails操作
```bash
# Railsコンソール
docker-compose exec app bundle exec rails console

# ルート確認
docker-compose exec app bundle exec rails routes

# その他のRailsコマンド
docker-compose exec app bundle exec rails [command]
```

---

## 🧪 テスト

### SSOログインフロー
1. https://localhost:3443 にアクセス
2. "Login with SSO"ボタンをクリック
3. IdPの認証画面（`https://idp.localhost/login`）が表示される
4. IdPでログイン（メール・パスワード・認証コード）
5. RPにリダイレクトされ、ログイン状態になる
6. ユーザー情報が表示される

### ログアウト
1. RPの"Logout"ボタンをクリック
2. IdPのセッションもクリアされる（グローバルログアウト）

---

## 📚 技術スタック

- **Container**: Docker + Docker Compose
- **Ruby**: 3.2.6
- **Rails**: 7.1.5
- **Authentication**: OmniAuth + OpenID Connect
- **Web Server**: nginx (HTTPS終端 + リバースプロキシ)

---

## 📖 設定ファイル

- **[docker/nginx/](./docker/nginx/)** - nginx SSL設定ファイル
- **[config/initializers/omniauth.rb](./config/initializers/omniauth.rb)** - OmniAuth設定

---

## 🔧 トラブルシューティング

### よくある問題

#### IdPに接続できない
```bash
# IdPが起動しているか確認
curl -k https://idp.localhost/health/ready

# sso-networkが存在するか確認
docker network ls | grep sso-network

# sso-networkがない場合は作成
docker network create sso-network
```

#### OAuth2エラー
- IdPでクライアントが正しく登録されているか確認
- `.env.local`のCLIENT_IDとCLIENT_SECRETが正しいか確認
- リダイレクトURIが `https://localhost:3443/auth/sso/callback` で登録されているか確認

#### SSL証明書エラー
- 開発環境では自己署名証明書を使用しているため、ブラウザで警告が出る場合があります
- 「詳細設定」→「安全でないサイトに進む」で進んでください

---

**最終更新**: 2025-10-18
