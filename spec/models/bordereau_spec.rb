# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bordereau, type: :model do
  describe "#populate_recensements" do
    let(:bordereau) { build(:bordereau, :with_recensements) }

    context "when there are no bordereau_recensements" do
      it "initializes a bordereau_recensement for each recensement" do
        bordereau_recensement = bordereau.populate_recensements

        expect(bordereau_recensement.size).to eq bordereau.edifice.objets.size
        expect(bordereau_recensement.all?(&:new_record?)).to eq true
      end
    end
    context "when bordereau_recensements already exist" do
      it "lists existing bordereau_recensements" do
        bordereau.bordereau_recensements.build(recensement: bordereau.dossier.recensements.first)
        bordereau.save

        bordereau_recensement = bordereau.populate_recensements

        expect(bordereau_recensement.size).to eq bordereau.edifice.objets.size
        expect(bordereau_recensement.select(&:persisted?).size).to eq 1
      end
    end
  end

  describe "#persist(params)" do
    let(:bordereau) { build(:bordereau) }

    context "when params is empty" do
      let(:params) { {} }
      it "returns nil" do
        expect(bordereau.persist(params)).to eq nil
      end
    end
    context "when params contains edifice_nom" do
      let(:params) { { edifice_nom: "Nouveau nom" } }
      it "updates edifice_nom" do
        expect { bordereau.persist(params) }.to change(bordereau, :edifice_nom).to("Nouveau nom")
      end
    end
  end
end
