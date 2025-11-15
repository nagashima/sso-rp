class ApiTestController < ApplicationController
  skip_before_action :authenticate_user!

  require 'net/http'
  require 'uri'
  require 'base64'
  require 'json'

  # GET /api_test
  def index
    # API検証メニュー
  end

  # GET /api_test/user
  def user
    # ユーザー情報取得フォーム
  end

  # POST /api_test/user
  def get_user
    user_id = params[:user_id]

    if user_id.blank?
      @error = 'User IDを入力してください'
      render :user
      return
    end

    # IdP APIにリクエスト
    idp_base_url = ENV['IDP_BASE_URL'] || 'https://host.docker.internal:4443'
    url = "#{idp_base_url}/api/v1/users/#{user_id}"

    @request_url = url
    @client_id = ENV['OAUTH_CLIENT_ID']

    begin
      uri = URI.parse(url)
      request = Net::HTTP::Get.new(uri)

      # Basic認証ヘッダー
      credentials = Base64.strict_encode64("#{ENV['OAUTH_CLIENT_ID']}:#{ENV['OAUTH_CLIENT_SECRET']}")
      request['Authorization'] = "Basic #{credentials}"

      # HTTPSリクエスト
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE # 開発環境用（本番では削除）

      response = http.request(request)

      @status_code = response.code
      @response_body = JSON.pretty_generate(JSON.parse(response.body))

    rescue => e
      @error = "API呼び出しエラー: #{e.message}"
    end

    render :user
  end

  # GET /api_test/search
  def search
    # ユーザー検索フォーム
  end

  # POST /api_test/search
  def search_users
    # 検索条件チェック
    search_params = {}
    search_params[:ids] = params[:ids] if params[:ids].present?
    search_params[:name] = params[:name] if params[:name].present?
    search_params[:kana_name] = params[:kana_name] if params[:kana_name].present?
    search_params[:phone_number] = params[:phone_number] if params[:phone_number].present?
    search_params[:limit] = params[:limit] if params[:limit].present?
    search_params[:offset] = params[:offset] if params[:offset].present?

    if search_params.except(:limit, :offset).empty?
      @error = '検索条件を入力してください'
      render :search
      return
    end

    # IdP APIにリクエスト
    idp_base_url = ENV['IDP_BASE_URL'] || 'https://host.docker.internal:4443'
    url = "#{idp_base_url}/api/v1/users?#{search_params.to_query}"

    @request_url = url
    @client_id = ENV['OAUTH_CLIENT_ID']

    begin
      uri = URI.parse(url)
      request = Net::HTTP::Get.new(uri)

      # Basic認証ヘッダー
      credentials = Base64.strict_encode64("#{ENV['OAUTH_CLIENT_ID']}:#{ENV['OAUTH_CLIENT_SECRET']}")
      request['Authorization'] = "Basic #{credentials}"

      # HTTPSリクエスト
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      response = http.request(request)

      @status_code = response.code
      @response_body = JSON.pretty_generate(JSON.parse(response.body))

    rescue => e
      @error = "API呼び出しエラー: #{e.message}"
    end

    render :search
  end
end
