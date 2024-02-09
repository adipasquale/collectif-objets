# frozen_string_literal: true

module Users
  class SessionsController < ApplicationController
    before_action :require_no_authentication, only: %i[new create redirect_from_magic_token]
    before_action :redirect_with_devise_return_to, only: %i[new]
    before_action :set_email_user_and_commune, only: %i[new create]

    def new; end

    def create
      @session_authentication = SessionAuthentication.new(params[:email], params[:code])
      success = @session_authentication.perform { sign_in(_1) }
      unless success
        @error = @session_authentication.error_message
        return render(:new, status: :unprocessable_entity)
      end

      redirect_to after_sign_in_path_for(@session_authentication.user), notice: "Vous êtes maintenant connecté(e)"
    end

    def destroy
      warden.user(scope: :user, run_callbacks: false) # If there is no user
      warden.logout(:user)
      warden.clear_strategies_cache!(scope: :user)
      @current_user = nil
      redirect_to root_path, notice: "Vous êtes maintenant déconnecté(e)"
    end

    def redirect_from_magic_token
      user = User.find_by(magic_token_deprecated: params["magic-token"])
      if user.present?
        redirect_to(
          new_user_session_code_path(code_insee: user.commune.code_insee),
          alert: "ce lien de connexion n’est plus valide"
        )
      else
        redirect_to new_user_session_code_path, alert: "ce lien de connexion n’est plus valide"
      end
    end

    private

    def redirect_with_devise_return_to
      return true if params[:email].present?

      match_data = session["user_return_to"]&.match(%r{^/communes/(\d+)/})
      return true unless match_data

      commune = Commune.find(match_data[1].to_i)
      return true if commune.nil?

      redirect_to new_user_session_code_path(code_insee: commune.code_insee)
    end

    def set_email_user_and_commune
      @email = params[:email]
      return redirect_to new_user_session_code_path if @email.blank?

      @user = User.find_by(email: params[:email])
      return redirect_to new_user_session_code_path if @user.blank?

      @commune = @user.commune
    end

    def redirect_with_error
      message = {
        user_does_not_have_valid_code: "Le code de connexion a expiré, veuillez en redemander un",
        mismatch: "Le code de connexion est incorrect"
      }[@session_authentication.error]
      message ||= "Une erreur s’est produite, veuillez redemander un code de connexion"
      flash[:alert] = message
      params = { code_sent: "true" }
      params[:code_insee] = @session_authentication.user.commune.code_insee if @session_authentication.user&.commune
      redirect_to new_user_session_code_path(params)
    end
  end
end
