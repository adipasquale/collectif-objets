# frozen_string_literal: true

require "rails_helper"

RSpec.describe Communes::CompletionsController, type: :request do
  let(:commune) { create(:commune, :with_user, :en_cours_de_recensement) }
  let(:objet) { create(:objet, commune:) }
  let(:recensement) { create(:recensement, objet:) }
  let(:dossier) { commune.dossier }
  let(:user) { commune.user }

  before(:each) { login_as(user, scope: :user) }

  context "POST communes/1/completion/new" do
    it "soumet le dossier" do
      path = commune_completion_path(commune)
      notes_commune = "Notes commune"
      recenseur = "Recenseur"
      params = { dossier_completion: { notes_commune:, recenseur: } }
      expect do
        post(path, params:)
        dossier.reload # Requis parce qu'on passe par commune pour obtenir le dossier
      end.to change(dossier, :status).from("construction").to("submitted")
      expect(dossier.notes_commune).to eq notes_commune
      expect(dossier.recenseur).to eq recenseur
    end
  end
end
