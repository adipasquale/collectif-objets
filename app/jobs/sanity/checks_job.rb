# frozen_string_literal: true

module Sanity
  class ChecksJob < ApplicationJob
    EMAIL = "brice.durand@beta.gouv.fr"

    def perform
      check_commune_started_dossier_construction
      check_commune_completed_dossier_submitted
      check_campaign_statuses_and_dates
    end

    protected

    def check_commune_started_dossier_construction
      Commune.started.joins(:dossier).where.not(dossiers: { status: :construction }).find_each do |commune|
        text = "La commune #{commune} est en `started` mais son dossier est " \
               "`#{commune.dossier.status}` au lieu de `construction`"
        logger.info text
        AdminMailer.with(email: EMAIL, commune:, text:).sanity_check_alert.deliver_later
      end
    end

    def check_commune_completed_dossier_submitted
      Commune.completed.joins(:dossier)
        .where.not(dossiers: { status: %i[submitted accepted] })
        .find_each do |commune|
        text = "La commune #{commune} est en `completed` mais son dossier est " \
               "`#{commune.dossier.status}` au lieu de `submitted` ou `accepted`"
        logger.info text
        AdminMailer.with(email: EMAIL, commune:, text:).sanity_check_alert.deliver_later
      end
    end

    def check_campaign_statuses_and_dates
      Campaign.ongoing.where("date_fin < ?", Time.zone.today - 1.day).find_each do |campaign|
        # this will warn for campaigns that should have ended the day before yesterday
        # because the cron job that closes them runs later in the day than this job
        text = "La campagne #{campaign} est en en cours mais sa date de fin est " \
               "#{campaign.date_fin} au lieu d'être dans le futur"
        logger.info text
        AdminMailer.with(email: EMAIL, campaign:, text:).sanity_check_alert.deliver_later
      end
      Campaign.planned.where("date_lancement < ?", Time.zone.today).find_each do |campaign|
        text = "La campagne #{campaign} est planifiée mais sa date de lancement est " \
               "#{campaign.date_lancement} au lieu d'être dans le futur"
        logger.info text
        AdminMailer.with(email: EMAIL, campaign:, text:).sanity_check_alert.deliver_later
      end
    end
  end
end
