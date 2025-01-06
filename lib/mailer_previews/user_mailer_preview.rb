# frozen_string_literal: true

class UserMailerPreview < ApplicationMailerPreview
  def session_code_email
    session_code = SessionCode.new(
      user: User.new(email: "mairie@thoiry.fr").tap(&:readonly!),
      code: "234045"
    )
    UserMailer.with(session_code:).session_code_email
  end

  def commune_completed_email
    UserMailer.with(user:, commune:).commune_completed_email
  end

  def commune_avec_objets_verts_email
    UserMailer.with(user:, commune:).commune_avec_objets_verts_email
  end

  def dossier_accepted_email(dossier = nil, conservateur = nil)
    dossier = dossier&.clone || Dossier.find_by(status: "accepted")
    conservateur ||= dossier.conservateur
    UserMailer.with(dossier:, conservateur:).dossier_accepted_email
  end

  def dossier_auto_submitted
    UserMailer.with(user:, commune:).dossier_auto_submitted_email
  end

  def relance_dossier_incomplet
    UserMailer.with(user:, commune:).relance_dossier_incomplet
  end

  def derniere_relance_dossier_incomplet
    UserMailer.with(user:, commune:).derniere_relance_dossier_incomplet
  end

  def message_received
    message = Message.from_conservateur.first
    user = message.commune.user
    UserMailer.with(message:, user:).message_received_email
  end

  private

  def user = @user ||= User.order(Arel.sql("RANDOM()")).first
  def commune = user.commune
end
