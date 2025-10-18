FROM ruby:3.2.6-slim

# 環境変数設定
ENV RAILS_ENV="development" \
    BUNDLE_PATH="/usr/local/bundle" \
    LANG="C.UTF-8" \
    TZ="Asia/Tokyo"

# 必要なネイティブライブラリをインストール（OAuth2 gem compilation対応）
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    libyaml-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Gem dependencies
COPY Gemfile Gemfile.lock ./
RUN bundle install

# アプリケーションコードをコピー
COPY . .

# 一時ディレクトリ作成
RUN mkdir -p tmp/pids log

# デフォルトポート
EXPOSE 3000

# デフォルトコマンド
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]