# frozen_string_literal: true

module Campaigns
  class CronJob < ApplicationJob
    # this job should be executed daily around 10am
    def perform(date = Time.zone.today)
      Campaign.planned.where("date_lancement <= ?", date).find_each(&:start!)

      Campaign.ongoing.each { Campaigns::RunCampaignJob.perform_now(_1.id) }

      # strict comparison here so that it closes day after end
      Campaign.ongoing.where("date_fin < ?", date).find_each(&:finish!)

      # Envoi de la réponse automatique pour les communes n'ayant recensé que des objets verts
      # Valable uniquement pour les campagnes démarrées après le 05/10/2023
      Campaign.finished.where("date_lancement > ?", Date.new(2023, 10, 5)).find_each do |campaign|
        campaign.communes.includes(:users).find_each do |commune|
          next unless commune.shall_receive_email_objets_verts?(date)

          commune.dossier.update(replied_automatically_at: date)
          UserMailer.with(user: commune.user, commune:).commune_avec_objets_verts_email.deliver_later
        end
      end
    end
  end
end
