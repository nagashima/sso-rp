class HomeController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    # ログイン済みの場合はプロフィールページにリダイレクト
    redirect_to profile_path if user_signed_in?

    # URLパラメータのinvite_codeはビューで直接使う（セッションには保存しない）
    # 理由: state検証の目的は「Hydra経由で返ってくるか」なので、
    # RP内部のセッションで引き回すと検証の意味がない
  end
end