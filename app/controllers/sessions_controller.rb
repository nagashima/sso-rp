class SessionsController < ApplicationController
  skip_before_action :authenticate_user!

  # ログアウト処理はCSRF検証をスキップ（セッション切れ時のエラー回避）
  skip_forgery_protection only: [:destroy]

  def omniauth
    # OmniAuthがリダイレクトを処理
  end

  def omniauth_callback
    auth = request.env['omniauth.auth']

    Rails.logger.info "OAuth callback received"
    Rails.logger.info "Auth present: #{auth.present?}"
    Rails.logger.info "Auth data: #{auth.inspect}" if auth.present?

    # callbackで返ってきたstateパラメータを取得（OmniAuthの場合はCSRF用ランダム文字列）
    returned_state = params[:state]
    Rails.logger.info "Returned state: #{returned_state.inspect}"

    if auth.present?
      # ユーザー情報をセッションに保存
      user_info = {
        uid: auth.uid,
        email: auth.info.email,
        name: auth.info.name,
        access_token: auth.credentials.token,
        id_token: auth.credentials.id_token,
        # raw_infoから追加のプロフィール情報を取得
        birth_date: auth.extra&.raw_info&.birthdate,
        phone_number: auth.extra&.raw_info&.phone_number,
        address: auth.extra&.raw_info&.address
      }

      session[:user_info] = user_info
      session[:logged_in_at] = Time.current.to_s  # ログイン時刻を記録
      Rails.logger.info "User info saved to session: #{user_info.inspect}"
      Rails.logger.info "Session after save: #{session[:user_info].inspect}"

      redirect_to profile_path, notice: 'ログインしました'
    else
      Rails.logger.error "OAuth authentication failed - no auth data"
      redirect_to root_path, alert: 'ログインに失敗しました'
    end
  end

  def auth_failure
    error_type = params[:message] || 'unknown_error'
    error_details = request.env['omniauth.error'] || 'No details available'

    Rails.logger.error "OmniAuth authentication failed: #{error_type}"
    Rails.logger.error "Error details: #{error_details.inspect}"
    Rails.logger.error "Request params: #{params.inspect}"
    Rails.logger.error "Request env omniauth: #{request.env.select { |k, v| k.to_s.include?('omniauth') }}"

    redirect_to root_path, alert: "ログインに失敗しました: #{error_type}"
  end

  def test_state_callback
    # 直接OAuth2フローのcallback（OmniAuthバイパス）
    code = params[:code]
    returned_state = params[:state]

    Rails.logger.info "=== Direct OAuth2 Test Callback ==="
    Rails.logger.info "Code: #{code}"
    Rails.logger.info "Returned state: #{returned_state}"

    if returned_state.present?
      begin
        state_data = JSON.parse(returned_state)
        invite_code = state_data['inviteCode']
        Rails.logger.info "✅ Successfully parsed state!"
        Rails.logger.info "Invite code: #{invite_code}"

        # flashで一度だけ表示（セッションには保存しない）
        flash[:notice] = "State parameter test successful! Invite code: #{invite_code}"
        flash[:returned_invite_code] = invite_code
        redirect_to root_path
      rescue JSON::ParserError => e
        Rails.logger.error "Failed to parse state: #{e.message}"
        flash[:alert] = "Failed to parse state: #{e.message}"
        redirect_to root_path
      end
    else
      Rails.logger.error "No state parameter returned!"
      flash[:alert] = "No state parameter in callback"
      redirect_to root_path
    end
  end

  def destroy
    # RPのローカルログアウト（セッションのみクリア）
    session[:user_info] = nil
    redirect_to root_path, notice: 'ログアウトしました'
  end
end