# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Backend
  impersonates :user
  impersonates :conservateur

  before_action :set_locale
  before_action :set_sentry_context
  before_action :redirect_if_demo_link

  def render_turbo_stream_update(*args, **kwargs)
    render(turbo_stream: [turbo_stream.update(*args, **kwargs)])
  end

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
    return params[:after_sign_in_path] if params[:after_sign_in_path].present?

    send("after_sign_in_path_for_#{resource.class.name.downcase}", resource)
  end

  def after_sign_in_path_for_user(user)
    commune_objets_path(user.commune)
  end

  def after_sign_in_path_for_conservateur(conservateur)
    return conservateurs_departement_path(conservateur.departements.first) if conservateur.departements.count == 1

    conservateurs_departements_path
  end

  def after_sign_in_path_for_adminuser(_admin_user)
    admin_path
  end

  def user_not_authorized
    flash[:alert] = "Vous n'avez pas le droit de faire cette action"
    redirect_back(fallback_location: root_path)
  end

  def redirect_if_demo_link
    return if params[:id] != "-1" &&
              params.keys.select { _1.end_with?("_id") }.none? { params[_1] == "-1" }

    redirect_to plan_path, alert: "Les liens et les formulaires des pages de démonstration ne fonctionnent pas"
  end
end
