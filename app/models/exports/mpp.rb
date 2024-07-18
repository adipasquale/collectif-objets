# frozen_string_literal: true

module Exports
  module Mpp
    module_function

    def to_csv(module_name)
      require "csv"

      CSV.generate(col_sep: ";") do |csv|
        csv << module_name.headers

        module_name.objets.find_each do |objet|
          csv << module_name.values(objet)
        end
      end
    end

    def dossier_url(dossier)
      Rails.application.routes.url_helpers.admin_dossier_url(dossier)
    end

    module Deplaces
      module_function

      def objets
        Objet.déplacés.examinés.order("dossiers.accepted_at DESC, recensements.created_at DESC")
          .includes(:departement, :commune, :edifice, :recensement)
          .includes(recensement: [:dossier, :nouvelle_commune])
      end

      def headers
        [
          "PM",
          "Département d'origine",
          "Code INSEE d'origine",
          "Nom de la commune d'origine",
          "Édifice d'origine",
          "Département de déplacement",
          "WEB (nouveau code INSEE)",
          "Commune de déplacement",
          "MOSA (nouvel édifice)",
          "Région de déplacement",
          "Date de validation du dossier par le conservateur",
          "DEPL",
          "Rapport"
        ]
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def values(objet)
        lieu_de_deplacement = [
          objet.nouveau_departement&.region || objet.departement&.region,
          objet.nouveau_departement&.code || objet.departement.code,
          objet.nouvelle_commune&.nom || objet.commune&.nom,
          "#{objet.nouvel_edifice} (Collectif Objets #{objet.recensement.dossier.accepted_at.year})"
        ].join(" ; ")
        [
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
          Mpp.dossier_url(objet.recensement.dossier)
        ]
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def to_csv
        Mpp.to_csv(self)
      end
    end

    module Manquants
      module_function

      def objets
        Objet.manquants.examinés.order("dossiers.accepted_at DESC, recensements.created_at DESC")
          .includes(:departement, :commune, :recensement, recensement: :dossier)
      end

      def headers
        [
          "PM",
          "Département d'origine",
          "Code INSEE d'origine",
          "Commentaire général de la commune",
          "Commentaire général du conservateur",
          "Commentaire de la commune sur l'objet",
          "Commentaire du conservateur sur l'objet",
          "Date de validation par le conservateur",
          "Manquant",
          "Vol",
          "Rapport"
        ]
      end

      def values(objet)
        [
          objet.palissy_REF,
          objet.departement.nom,
          objet.lieu_actuel_code_insee,
          objet.recensement.dossier.notes_commune,
          objet.recensement.dossier.notes_conservateur,
          objet.recensement.notes,
          objet.recensement.analyse_notes,
          I18n.l(objet.recensement.dossier.accepted_at, format: :long).upcase_first,
          "Manquant",
          "Œuvre déclarée manquante au moment du recensement Collectif Objets en #{
            objet.recensement.dossier.accepted_at.year}",
          Mpp.dossier_url(objet.recensement.dossier)
        ]
      end

      def to_csv
        Mpp.to_csv(self)
      end
    end
  end
end
