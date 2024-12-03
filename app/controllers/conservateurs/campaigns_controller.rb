# frozen_string_literal: true

module Conservateurs
  class CampaignsController < BaseController
    include CampaignsControllerConcern

    # rubocop:disable Rails/LexicallyScopedActionFilter
    # Certaines actions sont définies dans le concern partagés par admins et conservateurs
    before_action :authorize_campaign, except: %i[new create]
    before_action :set_show_new_selection_message, only: :edit_recipients
    after_action :enqueue_admin_mail, only: %i[update_status]
    # rubocop:enable Rails/LexicallyScopedActionFilter

    def new
      @departement = Departement.find(params[:departement_id])
      @campaign = Campaign.new(departement: @departement)
      authorize(@campaign)

      defaults = @departement.campaigns.select(:sender_name, :nom_drac, :signature).last&.attributes
      defaults ||= {
        sender_name: current_conservateur.full_name,
        nom_drac: @departement.region,
        signature: [
          current_conservateur.full_name,
          nil,
          "conservateur en charge des monuments historiques",
          "DRAC #{@departement.region}"
        ].join("\n")
      }
      @campaign.assign_attributes(defaults)
    end

    private

    def enqueue_admin_mail
      return if @status_event != "plan" || !@success

      AdminMailer.campaign_planned(current_conservateur, @campaign).deliver_later
    end

    def routes_prefix = :conservateurs
    def after_destroy_path = conservateurs_departement_path @campaign.departement
    def authorize_campaign = authorize @campaign
    def active_nav_links = ["Mes départements", @departement.to_s]

    def set_show_new_selection_message
      date = Date.new(2024, 6, 10)
      return if date.before?(1.year.ago)

      # N'afficher que pour les conservateurs ayant créés des campagnes
      # avant, et pas après le changement
      departement = @campaign.departement
      @show_new_selection_message =
        departement.campaigns.where("created_at < ?", date).exists? &&
        departement.campaigns.where.not("created_at > ?", date).exists?
    end
  end
end
