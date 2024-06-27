# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Backend
  impersonates :user
  impersonates :conservateur

  devise_group :person, contains: [:user, :conservateur, :admin]

  before_action :init_banners
  before_action :set_locale
  before_action :set_sentry_context
  before_action :set_permissions_policy_header

  def render_turbo_stream_update(*, **)
    render(turbo_stream: [turbo_stream.update(*, **)])
  end

  rescue_from ActiveRecord::RecordNotFound, with: :page_not_found
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def set_sentry_context
    if current_user
      set_sentry_current_user_context
    elsif current_conservateur
      set_sentry_current_conservateur_context
    end
  end

  def set_sentry_current_user_context
    Sentry.set_user(
      id: current_user.id,
      email: current_user.email,
      username: current_user.commune&.nom || current_user.email,
      ip_address: "{{auto}}",
      user_type: "user"
    )
  end

  def set_sentry_current_conservateur_context
    Sentry.set_user(
      id: current_conservateur.id,
      email: current_conservateur.email,
      username: current_conservateur.to_s,
      ip_address: "{{auto}}",
      user_type: "conservateur"
    )
  end

  def set_locale
    I18n.locale = I18n.default_locale
  end

  def after_sign_in_path_for(resource)
    # after_sign_in_path_for = stored_location_for || signed_in_root_path
    # we do not want to override the stored location if there is one
    send("after_sign_in_path_for_#{resource.class.name.downcase}", resource)
  end

  def after_sign_in_path_for_user(user)
    return commune_premiere_visite_path(user.commune) if user.commune.recensements.completed.empty?

    # NOTE: calling stored_location_for here is weird : it gets and deletes the value
    stored_location_for(user) || commune_objets_path(user.commune)
  end

  def after_sign_in_path_for_conservateur(conservateur)
    return conservateurs_departement_path(conservateur.departements.first) if conservateur.departements.count == 1

    conservateurs_departements_path
  end

  def after_sign_in_path_for_adminuser(_admin_user)
    admin_path
  end

  def user_not_authorized(exception)
    message = "Vous n'avez pas le droit de faire cette action"
    message += " : #{exception.message}" if Rails.env.development?
    flash[:alert] = message
    redirect_back(fallback_location: root_path)
  end

  def page_not_found
    render "errors/not_found", status: :not_found
  end

  helper_method :active_nav_links
  def active_nav_links = []

  def init_banners
    @banners = []
    @banners << :environment if %w[development staging].include?(Rails.configuration.x.environment_specific_name)
    @banners << :user_impersonate if impersonating_user?
    @banners << :conservateur_impersonate if current_conservateur.present? && current_conservateur != true_conservateur
  end

  def impersonating_user?
    admin_user_signed_in? &&
      current_user.present? &&
      current_user != true_user
  end

  # this overrides the default devise method
  def require_no_authentication
    redirect_to after_sign_in_path_for(current_person), notice: "Vous êtes déjà connecté•e" if person_signed_in?
  end

  # The Permissions policy header now replaces the Features policy
  # But Rails 7 doesn't automatically use the new header
  # See https://github.com/rails/rails/pull/41994
  def set_permissions_policy_header
    permission_directives = Rails.application.config.permissions_policy.directives
    response.headers["Permissions-Policy"] = permission_directives.map do |directive, sources|
      if sources.include? "'none'"
        "#{directive}=()"
      elsif sources.include? "'self'"
        "#{directive}=(#{sources.join(' ')})"
      elsif sources.include? "'all'"
        "#{directive}=(*)"
      end
    end.compact.join(", ")
  end
end
