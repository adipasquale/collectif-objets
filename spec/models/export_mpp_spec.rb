# frozen_string_literal: true

require "rails_helper"

RSpec.describe Exports::Mpp, type: :model do
  let(:commune) { create(:commune, :en_cours_de_recensement) }

  context "::Deplaces" do
    let(:exporter) { Exports::Mpp::Deplaces }
    describe "#objets" do
      it "liste les objets" do
        create(:objet, commune:)
        create(:objet, :disparu, commune:)
        objets = create_list(:objet, 3, :deplace_et_examine, commune:)
        conservateur = create(:conservateur, departements: [commune.departement])
        commune.dossier.update(conservateur:)
        commune.dossier.submit!
        commune.dossier.accept!
        expect(exporter.objets).to eq objets.sort_by { |objet| objet.recensement.created_at }.reverse
      end
    end
    describe "#values(objet)" do
      it "liste les valeurs d'un objet" do
        objet = create(:objet, :deplace_et_examine, commune:)
        conservateur = create(:conservateur, departements: [commune.departement])
        commune.dossier.update(conservateur:)
        commune.dossier.submit!
        commune.dossier.accept!
        lieu_de_deplacement = [
          objet.nouveau_departement&.region || objet.departement&.region,
          objet.nouveau_departement&.code || objet.departement.code,
          objet.nouvelle_commune&.nom || objet.commune&.nom,
          "#{objet.nouvel_edifice} (Collectif Objets #{objet.recensement.dossier.accepted_at.year})"
        ].join(" ; ")
        expectation = [
          objet.palissy_REF,
          objet.departement.nom,
          objet.palissy_INSEE,
          objet.commune.nom,
          objet.edifice&.nom&.upcase_first,
          objet.nouveau_departement&.nom,
          objet.nouvelle_commune&.code_insee,
          objet.nouvelle_commune&.nom,
          objet.nouvel_edifice&.upcase_first,
          objet.nouveau_departement&.region || objet.departement.region,
          I18n.l(objet.recensement.dossier.accepted_at, format: :long).upcase_first,
          "Lieu de déplacement : #{lieu_de_deplacement}",
          Exports::Mpp.dossier_url(objet.recensement.dossier)
        ]
        expect(exporter.values(objet)).to eq expectation
      end
    end
  end

  context "::Manquants" do
    let(:exporter) { Exports::Mpp::Manquants }
    describe "#objets" do
      it "liste les objets" do
        create(:objet, commune:)
        create(:objet, :deplace, commune:)
        objets = create_list(:objet, 3, :disparu_et_examine, commune:)
        conservateur = create(:conservateur, departements: [commune.departement])
        commune.dossier.update(conservateur:)
        commune.dossier.submit!
        commune.dossier.accept!
        expect(exporter.objets).to eq objets.sort_by { |objet| objet.recensement.created_at }.reverse
      end
    end
    describe "#values(objet)" do
      it "liste les valeurs d'un objet" do
        objet = create(:objet, :disparu_et_examine, commune:)
        conservateur = create(:conservateur, departements: [commune.departement])
        commune.dossier.update(conservateur:)
        commune.dossier.submit!
        commune.dossier.accept!
        expectation = [
          objet.palissy_REF,
          objet.departement.nom,
          objet.lieu_actuel_code_insee,
          objet.recensement.notes,
          objet.recensement.dossier.notes_commune,
          objet.recensement.dossier.notes_conservateur,
          objet.recensement.notes,
          objet.recensement.analyse_notes,
          I18n.l(objet.recensement.dossier.accepted_at, format: :long).upcase_first,
          "Manquant",
          "Œuvre déclarée manquante au moment du recensement Collectif Objets en #{
            objet.recensement.dossier.accepted_at.year}",
          Exports::Mpp.dossier_url(objet.recensement.dossier)
        ]
        expect(exporter.values(objet)).to eq expectation
      end
    end
  end
end
