# frozen_string_literal: true

module CampaignsControllerConcern
  extend ActiveSupport::Concern
  include ActionView::Helpers::SanitizeHelper

  included do
    before_action \
      :set_campaign,
      only: %i[show mail_previews edit edit_recipients update_recipients update_status update destroy]
    before_action :set_excluded_communes, only: %i[show update_status]
    before_action :redirect_planned_campaign, only: %i[edit_recipients]

    # Temporarily allow inline styles when previewing emails
    content_security_policy { |policy| policy.style_src :self, :unsafe_inline }
  end

  def show; end

  def edit_recipients
    @communes_ids = @campaign.commune_ids
  end

  def edit; end

  def create
    @campaign = Campaign.new campaign_params_sanitized
    @departement = @campaign.departement
    authorize_campaign
    if @campaign.save
      redirect_to send("#{routes_prefix}_campaign_edit_recipients_path", @campaign),
                  notice: "La campagne a été créée avec succès, elle peut être configurée"
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @campaign.update campaign_params_sanitized
      redirect_to send("#{routes_prefix}_campaign_path", @campaign), notice: "La campagne a été modifiée"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def update_recipients
    @campaign.commune_ids = params_recipient_commune_ids
    redirect_to send("#{routes_prefix}_campaign_path", @campaign),
                notice: "Les destinataires de la campagne ont été modifiés"
  rescue ActiveRecord::RecordInvalid => e
    @communes_ids = params_recipient_commune_ids
    render :edit_recipients,
           status: :unprocessable_content,
           alert: "#{e.record.commune.nom} : #{e.record.errors.first.message}"
  end

  def update_status
    if @campaign.aasm.fire! params.require(:campaign).require(:status_event)
      redirect_to send("#{routes_prefix}_campaign_path", @campaign), notice: "La campagne a été modifiée"
    else
      render :show, status: :unprocessable_content
    end
  end

  def destroy
    if @campaign.destroy
      redirect_to after_destroy_path, status: :see_other, notice: "Le brouillon de campagne a été supprimé"
    else
      @campaign.errors.add(:base, "Impossible de supprimer ce brouillon de campagne")
      render :show, status: :unprocessable_content
    end
  end

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def mail_previews
    commune_id = params[:commune_id]
    @recipient = @campaign.recipients.find_by(commune_id:) if commune_id
    @recipient ||= @campaign.recipients.first
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  private

  def params_recipient_commune_ids
    params.dig(:campaign, :commune_ids).map(&:to_i)
  end

  def set_campaign
    @campaign = Campaign.find(params[:campaign_id] || params[:id])
  end

  def set_excluded_communes
    @excluded_communes = @campaign.excluded_communes
  end

  def campaign_params
    params.require(:campaign)
      .permit(
        :departement_code, :date_lancement, :date_relance1,
        :date_relance2, :date_relance3, :date_fin,
        :sender_name, :signature, :nom_drac
      )
  end

  def campaign_params_sanitized
    campaign_params.merge \
      %i[sender_name signature nom_drac].index_with { sanitize(campaign_params[_1]) }
  end

  def redirect_planned_campaign
    return if @campaign.draft?

    redirect_to(
      [routes_prefix, @campaign],
      alert: "Impossible de modifier les communes destinataires de cette campagne car elle n'est plus en brouillon"
    )
  end
end
