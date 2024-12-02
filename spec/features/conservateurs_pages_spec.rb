# frozen_string_literal: true

require "rails_helper"

feature "Conservateurs", js: true do
  let!(:conservateur) { create(:conservateur, departements: [create(:departement)]) }
  let(:departement) { conservateur.departements.first }
  let(:campaign) { create(:campaign, :draft, departement:) }
  let(:commune) { create(:commune, departement:) }

  shared_examples "an accessible page" do |excludes|
    it "should be accessible" do
      login_as conservateur, scope: :conservateur
      visit path
      expect(page).to have_current_path(path)
      expect(page.title).not_to eq("Collectif Objets") # Le titre par défaut
      expect(page).to be_axe_clean.excluding(*excludes)
    end
  end

  describe "registrations/edit" do
    let(:path) { edit_conservateur_registration_path }
    it_behaves_like "an accessible page"
  end

  describe "visits" do
    let(:path) { conservateurs_visits_path }
    it_behaves_like "an accessible page"
  end

  describe "fiches" do
    let(:path) { conservateurs_fiches_path }
    it_behaves_like "an accessible page"
  end

  describe "departements" do
    let(:path) { conservateurs_departements_path }
    it_behaves_like "an accessible page"
  end

  describe "departements/1" do
    let(:path) { conservateurs_departement_path(departement) }
    it_behaves_like "an accessible page"
  end

  describe "departements/1?vue=carte" do
    let(:path) { conservateurs_departement_path(departement, vue: :carte) }
    it_behaves_like "an accessible page"
  end

  describe "campaigns/new" do
    let(:path) { new_conservateurs_departement_campaign_path(departement) }
    it_behaves_like "an accessible page"
  end

  describe "campaigns/show" do
    let(:path) { conservateurs_campaign_path(campaign) }
    it_behaves_like "an accessible page"
  end

  describe "campaigns/1/edit" do
    let(:path) { edit_conservateurs_campaign_path(campaign) }
    it_behaves_like "an accessible page"
  end

  describe "campaigns/1/edit_recipients" do
    let(:path) { conservateurs_campaign_edit_recipients_path(campaign) }
    it_behaves_like "an accessible page"
  end

  describe "campaigns/1/mail_previews" do
    let!(:recipient) { create(:recipient, campaign:) }
    let(:path) { conservateurs_campaign_mail_previews_path(campaign) }
    it_behaves_like "an accessible page", :iframe
  end

  describe "communes/1" do
    let(:objet) { create(:objet, commune:) }
    let(:dossier) { create(:dossier, :submitted, commune:, conservateur:) }
    let!(:recensement) { create(:recensement, objet:, dossier:) }
    let(:path) { conservateurs_commune_path(commune) }
    it_behaves_like "an accessible page"
  end

  describe "communes/1/messages" do
    let(:path) { conservateurs_commune_messages_path(commune) }
    it_behaves_like "an accessible page"
  end

  describe "communes/1/messages/new" do
    let(:path) { new_conservateurs_commune_message_path(commune) }
    it_behaves_like "an accessible page"
  end

  describe "communes/1/dossier" do
    let!(:dossier) { create(:dossier, :submitted, conservateur:) }
    let(:path) { conservateurs_commune_dossier_path(commune) }
    it_behaves_like "an accessible page"
  end

  describe "dossiers/1/accept/new" do
    let(:commune) { create(:commune, :completed, departement:) }
    let(:path) { new_conservateurs_dossier_accept_path(commune.dossier) }
    it_behaves_like "an accessible page"
  end

  describe "communes/1/historique" do
    let(:dossier) { create(:dossier, :archived, commune:, conservateur:) }
    let(:path) { conservateurs_commune_historique_path(dossier.commune) }
    it_behaves_like "an accessible page"
  end

  describe "communes/1/bordereaux" do
    let(:dossier) { create(:dossier, :accepted, commune:, conservateur:) }
    let(:path) { conservateurs_commune_bordereaux_path(dossier.commune) }
    it_behaves_like "an accessible page"
  end

  describe "communes/1/deleted_recensements" do
    let(:objet) { create(:objet, commune:) }
    let(:dossier) { create(:dossier, :accepted, commune:, conservateur:) }
    let(:recensement) { create(:recensement, :supprimé, objet:, dossier:) }
    let(:path) { conservateurs_commune_deleted_recensements_path(recensement.commune) }
    it_behaves_like "an accessible page"
  end

  describe "objets/1/recensements/1/analyse/edit" do
    let(:commune) { create(:commune, :completed, departement:) }
    let(:objet) { create(:objet, commune:) }
    let(:recensement) { create(:recensement, objet:, dossier: commune.dossier) }
    let(:path) { edit_conservateurs_objet_recensement_analyse_path(objet, recensement) }
    it_behaves_like "an accessible page"
  end
end
