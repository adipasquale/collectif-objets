# frozen_string_literal: true

require "rails_helper"

RSpec.describe Synchronizer::Communes::Revision do
  let(:revision) { described_class.new(commune_and_user_attributes, persisted_commune:) }
  let!(:departement) { create(:departement, code: "01") }

  let(:base_commune_and_user_attributes) do
    {
      commune: { code_insee: "01001", nom: "Ambérieu", phone_number: "01 02 03 04 05", departement_code: "01" },
      user: { email: "contact@amberieu.fr" }
    }
  end

  context "no existing commune" do
    let(:commune_and_user_attributes) { base_commune_and_user_attributes }
    let(:persisted_commune) { nil }

    it "creates a new commune" do
      expect(revision.synchronize).to eq true
      commune = Commune.find_by(code_insee: "01001")
      expect(commune.nom).to eq "Ambérieu"
      expect(commune.phone_number).to eq "01 02 03 04 05"
      expect(commune.departement_code).to eq "01"
      user = commune.user
      expect(user.email).to eq "contact@amberieu.fr"
      expect(revision.action_commune).to eq :create
      expect(revision.action_user).to eq :create
    end
  end

  context "existing commune without user" do
    let(:commune_and_user_attributes) { base_commune_and_user_attributes }

    let!(:persisted_commune) do
      Commune.create(code_insee: "01001", nom: "Ambérieu-sur-mer", phone_number: "01 01 01 01 01",
                     departement_code: "01")
    end

    it "updates the commune & creates the user" do
      expect(revision.synchronize).to eq true
      commune = Commune.find_by(code_insee: "01001")
      expect(commune.nom).to eq "Ambérieu"
      expect(commune.phone_number).to eq "01 02 03 04 05"
      expect(commune.departement_code).to eq "01"
      user = commune.user
      expect(user.email).to eq "contact@amberieu.fr"
      expect(revision.action_commune).to eq :update
      expect(revision.action_user).to eq :create
    end
  end

  context "existing commune & existing user" do
    let(:commune_and_user_attributes) { base_commune_and_user_attributes }

    let!(:persisted_commune) do
      create(
        :commune, :with_user,
        code_insee: "01001", nom: "Ambérieu-sur-mer", phone_number: "01 01 01 01 01",
        departement:
      )
    end

    before do
      persisted_commune.user.update!(email: "anciencontact@amberieu.fr")
    end

    it "updates the commune & updates the user email" do
      expect(revision.synchronize).to eq true
      commune = Commune.find_by(code_insee: "01001")
      expect(commune.nom).to eq "Ambérieu"
      expect(commune.phone_number).to eq "01 02 03 04 05"
      expect(commune.departement_code).to eq "01"
      user = commune.user
      expect(user.email).to eq "contact@amberieu.fr"
      expect(revision.action_commune).to eq :update
      expect(revision.action_user).to eq :update_email
    end

    context "email has disappeared" do
      let(:commune_and_user_attributes) { base_commune_and_user_attributes.merge(user: { email: nil }) }

      it "commune should be updates & user destroyed" do
        expect(revision.synchronize).to eq true
        commune = Commune.find_by(code_insee: "01001")
        expect(commune.nom).to eq "Ambérieu"
        expect(commune.phone_number).to eq "01 02 03 04 05"
        expect(commune.departement_code).to eq "01"
        expect(commune.users).to be_empty
        expect(revision.action_commune).to eq :update
        expect(revision.action_user).to eq :destroy
      end
    end
  end
end
