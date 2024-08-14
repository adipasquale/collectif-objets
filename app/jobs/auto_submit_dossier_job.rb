# frozen_string_literal: true

class AutoSubmitDossierJob < ApplicationJob
  def perform(dossier_id)
    @dossier = Dossier.find(dossier_id)
    dossier.submit!(notes_commune: "Dossier soumis automatiquement 1 mois après le dernier recensement")
    UserMailer.with(user:, commune:).dossier_auto_submitted_email.deliver_later
    SendMattermostNotificationJob.perform_later("dossier_auto_submitted", { "dossier_id" => dossier.id })
  end

  private

  attr_reader :dossier

  delegate :commune, to: :dossier

  def user
    dossier.commune.user
  end
end
