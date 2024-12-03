# frozen_string_literal: true

class CampaignV1Mailer < ApplicationMailer
  layout "campaign_v1_mailer"
  before_action :set_campaign_commune_and_user
  default \
    to: -> { @user.email },
    from: -> {
            email_address_with_name(@commune.support_email(role: :user),
                                    "#{@campaign.sender_name} via Collectif Objets")
          }

  MAIL_NAMES = (
    %w[lancement] +
    %w[relance1_inactive relance2_inactive relance3_inactive fin_inactive] +
    %w[relance2_started relance3_started fin_started] +
    %w[relance2_to_complete relance3_to_complete fin_to_complete]
  ).freeze

  MAIL_NAMES.each do |name|
    define_method "#{name}_email" do
      mail(subject: "[DRAC #{@campaign.nom_drac}] #{t("campaign_v1_mailer.#{name}.subject", **i18n_args)}")
    end
  end

  def ct(key, **)
    I18n.t("campaign_v1_mailer.#{key}", **i18n_args.merge(**)).html_safe
  end
  helper_method :ct

  private

  def set_campaign_commune_and_user
    @campaign, @commune, @user, @campaign_recipient = params.values_at(:campaign, :commune, :user, :campaign_recipient)
    @campaign_recipient ||= @campaign.recipients.where(commune: @commune).first
    @departement = @campaign.departement
  end

  def i18n_args
    @i18n_args ||= {
      nom_drac: @campaign.nom_drac,
      dans_departement: @departement.dans_nom,
      nom_commune: @commune.nom,
      count: @commune.objets.size,
      nombre_communes: @campaign.communes.size,
      date_lancement: I18n.l(@campaign.date_lancement, format: :long_with_weekday),
      date_fin: I18n.l(@campaign.date_fin, format: :long_with_weekday),
      fin_dans_n_semaines: Time.zone.today.upto(@campaign.date_fin).count / 7,
      fin_dans_n_jours: Time.zone.today.upto(@campaign.date_fin).count
    }
  end
end
