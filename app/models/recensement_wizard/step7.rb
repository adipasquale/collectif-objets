# frozen_string_literal: true

module RecensementWizard
  class Step7 < Base
    TITLE = "Récapitulatif"

    def update(_params)
      recensement.complete! unless recensement.completed?
    end

    def after_success_path
      commune_objets_path(commune, recensement_saved: true, objet_id: objet.id)
    end
  end
end
