# frozen_string_literal: true

module RecensementWizard
  class Step2 < Base
    STEP_NUMBER = 2
    TITLE = "Précisions sur la localisation"

    attr_accessor :autre_edifice_checked

    validates :edifice_id,
              presence: { message: "Veuillez sélectionner un édifice ou \
                cocher la case ci-dessous si l'édifice n'est pas dans la liste." },
              unless: -> { autre_edifice_checked }

    validates \
      :edifice_nom,
      presence: {
        message: "Veuillez préciser le nom de l’édifice dans lequel l’objet a été déplacé"
      }, if: -> { autre_edifice_checked }

    def permitted_params = %i[edifice_id edifice_nom autre_edifice_checked]

    def initialize(recensement)
      super
      self.autre_edifice_checked = recensement.edifice_nom.present?
    end

    def assign_attributes(attributes)
      if attributes[:edifice_id].present? && attributes[:edifice_id] == "0"
        attributes[:autre_edifice_checked] = true
        attributes.delete(:edifice_id)
      end

      if attributes[:edifice_id].present? && attributes[:edifice_id] != "0"
        attributes[:autre_edifice_checked] = false
        attributes.delete(:edifice_nom)
      end

      super

      if autre_edifice_checked
        recensement.edifice_id = nil
      else
        recensement.edifice_nom = nil
      end
    end

    def autre_edifice?
      edifice_id.present? && edifice_id.zero?
    end
  end
end
