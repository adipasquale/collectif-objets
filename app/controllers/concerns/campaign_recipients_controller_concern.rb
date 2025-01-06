# frozen_string_literal: true

module CampaignRecipientsControllerConcern
  extend ActiveSupport::Concern

  included do
    before_action :set_instance_vars, :authorize_recipient
    before_action :validate_mail_preview_params, only: [:mail_preview]
  end

  def update
    if @recipient.update(recipient_params)
      redirect_to send("#{routes_prefix}_campaign_recipient_path", @recipient.campaign, @recipient),
                  notice: "Destinataire mis à jour"
    else
      render :show, status: :unprocessable_content
    end
  end

  def mail_preview
    mail = CampaignV1Mailer
      .with(user: @user, commune: @commune, campaign: @campaign)
      .send("#{mail_name}_email")
    render \
      partial: "shared/campaign_recipients/mail_preview",
      locals: { campaign: @campaign, recipient: @recipient, step: params[:step], variant: params[:variant], mail:,
                routes_prefix: }
  end

  private

  def recipient_params
    params.require(:campaign_recipient)
      .permit(:opt_out, :opt_out_reason)
      .merge(params[:campaign_recipient][:opt_out] == "0" ? { opt_out_reason: nil } : {})
  end

  def set_instance_vars
    @recipient = CampaignRecipient.includes(:campaign, :commune).find(params[:id] || params[:recipient_id])
    @commune = @recipient.commune
    @campaign = @recipient.campaign
    @user = @commune.user
  end

  def validate_mail_preview_params
    raise ActionController::UnpermittedParameters, %w[step] unless Campaign::STEPS.include?(params[:step])

    raise ActionController::UnpermittedParameters, %w[variant] \
      if params[:variant].present? && Co::Campaigns::Mail::VARIANTS.exclude?(params[:variant])

    raise StandardError, "mail #{mail_name} does not exist" unless CampaignV1Mailer::MAIL_NAMES.include?(mail_name)
  end

  def mail_name
    [params[:step], params[:variant]].compact.join("_")
  end
end
