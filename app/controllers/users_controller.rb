class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    # IdPのAPIから詳細なユーザー情報を取得
    @user_info = fetch_user_info_from_idp
  end

  private

  def fetch_user_info_from_idp
    return current_user unless current_user['access_token']

    begin
      uri = URI("#{ENV['IDP_API_INTERNAL_URL']}/user_info")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE  # 開発環境用：自己署名証明書を許可

      request = Net::HTTP::Get.new(uri)
      request['Authorization'] = "Bearer #{current_user['access_token']}"
      request['Content-Type'] = 'application/json'

      response = http.request(request)

      case response.code
      when '200'
        # IdP APIから取得したデータにセッションのトークン情報をマージ
        api_data = JSON.parse(response.body)
        current_user.merge(api_data)
      when '401'
        handle_access_token_expired
      else
        Rails.logger.error "Failed to fetch user info: #{response.code} #{response.body}"
        current_user
      end
    rescue => e
      Rails.logger.error "Error fetching user info: #{e.message}"
      current_user
    end
  end

  def handle_access_token_expired
    user_id = current_user&.dig('uid') || 'unknown'
    handle_token_expired(user_id)
    nil
  end
end