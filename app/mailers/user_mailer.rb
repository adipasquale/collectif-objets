# frozen_string_literal: true

class UserMailer < ApplicationMailer
  helper :messages

  before_action :set_commune_and_user, except: [:session_code_email, :dossier_accepted_email, :message_received_email]

  default to: -> { email_address_with_name(@user.email, (@commune || @user.commune)&.nom) },
          from: -> { email_address_with_name(@commune.support_email(role: :user), "Messagerie Collectif Objets") }

  def session_code_email
    @session_code = params[:session_code]
    @user = @session_code.user
    @commune = @user.commune
    @login_url = new_user_session_code_url(code_insee: @commune&.code_insee)
    mail subject: "Code de connexion Collectif Objets - envoyé à #{I18n.l(Time.zone.now, format: :time_first)} ",
         from: email_address_with_name(CONTACT_EMAIL, I18n.t("application_mailer_layout.project_name"))
  end

  def commune_completed_email
    @cta_url = commune_completion_url(@commune)
    mail subject: "#{@commune.nom}, merci dʼavoir contribué à Collectif Objets"
  end

  def commune_avec_objets_verts_email
    mail subject: "Suite à votre participation à la campagne de recensement " \
                  "des objets monuments historique #{@commune.departement.dans_nom}"
  end

  def dossier_accepted_email
    @dossier = params[:dossier]
    @commune = @dossier.commune
    @user = @commune.user
    @conservateur = @dossier.conservateur || params[:conservateur]
    @cta_url = commune_dossier_url(@commune)
    mail subject: "Examen du recensement des objets protégés de #{@commune.nom}",
         from: email_address_with_name(@commune.support_email(role: :user),
                                       "#{@conservateur.full_name} via Collectif Objets")
  end

  def dossier_auto_submitted_email
    @cta_url = commune_completion_url(@commune)
    mail subject: "Vos recensements d'objets ont été transmis aux conservateurs"
  end

  def relance_dossier_incomplet
    @cta_url = commune_objets_url(@commune)
    mail subject: "Plus que 3 mois pour pour finaliser votre recensement"
  end

  def derniere_relance_dossier_incomplet
    @cta_url = commune_objets_url(@commune)
    mail subject: "Plus qu'un mois pour pour finaliser votre recensement"
  end

  def message_received_email
    @message, @user = params.values_at(:message, :user)
    @author = @message.author
    @commune = @message.commune
    @cta_url = commune_messages_url(@commune)
    mail subject: "#{@author} vous a envoyé un message sur Collectif Objets",
         from: email_address_with_name(@commune.support_email(role: :user), "#{@author} via Collectif Objets")
  end

  protected

  def set_commune_and_user
    @user = params[:user]
    @commune = params[:commune]
  end
end
