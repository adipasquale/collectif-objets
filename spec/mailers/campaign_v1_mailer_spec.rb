# frozen_string_literal: true

require "rails_helper"
require_relative "shared_examples"

SIGNATURE = <<-SIG
  Jeanne Dupont

  Conservatrice en charge des monuments historiques

  10 rue de la république, SQY
SIG

RSpec.shared_examples "campaign email commons" do
  it "has a text and HTML part, a subject with drac, and the right emails" do
    # it "subject starts with drac name" do
    expect(mail.subject).to start_with "[DRAC IDF]"
    # it "recipient is users' email" do
    expect(mail.to).to eq(["jean@mairie.fr"])
    # it "sender is collectif objets" do
    expect(mail.from).to eq([commune.support_email(role: :user)])
  end

  describe "contains the campaign signature" do
    include_examples "both parts contain", "Jeanne Dupont"
    include_examples "both parts contain", "10 rue de la république, SQY"
  end
end

RSpec.shared_examples "a campaign email" do |email_name, mail_subject, content|
  include ActiveSupport::Testing::TimeHelpers

  describe email_name do
    let(:mail) { mailer_configured.send(email_name) }

    include_examples "campaign email commons"

    it "subject contains '#{mail_subject.truncate(80)}'" do
      expect(mail.subject).to include mail_subject
    end

    include_examples "both parts contain", content
  end
end

RSpec.describe CampaignV1Mailer, type: :mailer do
  let(:departement) { build(:departement, code: "78", nom: "Yvelines", dans_nom: "dans les Yvelines") }
  let!(:commune) { create(:commune_with_user, departement:, nom: "Joinville") }
  let!(:user) { commune.user }
  before { user.update!(email: "jean@mairie.fr") }
  before { travel_to(Time.zone.today.next_week(:monday).to_time + 10.hours) }
  let(:objet) { create(:objet, commune:) }
  let!(:campaign) do
    create(
      :campaign,
      departement:,
      nom_drac: "IDF",
      signature: SIGNATURE,
      date_lancement: Time.zone.today,
      date_relance1: 7.days.from_now,
      date_relance2: 14.days.from_now,
      date_relance3: 30.days.from_now,
      date_fin: 59.days.from_now
    )
  end
  let!(:campaign_recipient) { create(:campaign_recipient, commune:, campaign:) }

  before do
    allow(commune).to receive(:highlighted_objet).and_return(objet)
    allow(commune).to receive(:objets).and_return([objet])
  end

  let(:mailer_configured) { CampaignV1Mailer.with(user:, commune:, campaign:) }

  # LANCEMENT

  it_behaves_like(
    "a campaign email",
    :lancement_email,
    "Lancement du recensement des objets monuments historiques à Joinville",
    "Joinville abrite un objet protégé au titre des monuments historiques"
  )

  # RELANCE 1

  it_behaves_like(
    "a campaign email",
    :relance1_inactive_email,
    "Joinville, le recensement des objets monuments historiques dans les Yvelines est en cours",
    "Ce recensement est simple et ne vous prendra que quelques minutes par objet"
  )

  # RELANCE 2

  it_behaves_like(
    "a campaign email",
    :relance2_inactive_email,
    "Joinville, le recensement des objets monuments historiques dans les Yvelines est en cours",
    "Le recensement est simple et ne vous prendra que quelques minutes par objet"
  )

  it_behaves_like(
    "a campaign email",
    :relance2_started_email,
    "Rencontrez-vous des difficultés dans le recensement de vos objets protégés à Joinville ?",
    "Nous avons bien reçu vos premiers retours concernant les objets protégés de Joinville"
  )

  it_behaves_like(
    "a campaign email",
    :relance2_to_complete_email,
    "Il reste une dernière étape pour envoyer le dossier de recensement de Joinville",
    "Nous vous remercions d’avoir pris le temps de participer à la campagne de recensement"
  )

  # RELANCE 3

  it_behaves_like(
    "a campaign email",
    :relance3_inactive_email,
    "Plus que 60 jours pour recenser les objets monuments historiques de Joinville",
    "Ainsi, nous vous invitons à prendre part à ce recensement même si vous estimez que les objets protégés de votre commune sont en bon état" # rubocop:disable Layout/LineLength
  )

  it_behaves_like(
    "a campaign email",
    :relance3_started_email,
    "N’oubliez pas de finaliser le recensement des objets protégés de Joinville",
    "Nous vous remercions de contribuer à cette campagne de recensement participatif dans les Yvelines"
  )

  it_behaves_like(
    "a campaign email",
    :relance3_to_complete_email,
    "N’oubliez pas de finaliser le recensement des objets protégés de Joinville",
    "Pour transmettre votre dossier, il vous suffit de cliquer"
  )

  # FIN

  it_behaves_like(
    "a campaign email",
    :fin_inactive_email,
    "Dernier jour pour recenser les objets monuments historiques de Joinville",
    "Sauf erreur de notre part, vous n’avez pas participé à la campagne"
  )

  it_behaves_like(
    "a campaign email",
    :fin_started_email,
    "Dernier jour pour recenser les objets monuments historiques de Joinville",
    "Seul un dossier de recensement complet pourra être pris en compte"
  )

  it_behaves_like(
    "a campaign email",
    :fin_to_complete_email,
    "Dernier jour pour recenser les objets monuments historiques de Joinville",
    "Sauf erreur de notre part, vous n’avez pas effectué la dernière étape qui permet l’envoi du dossier de recensement"
  )
end
