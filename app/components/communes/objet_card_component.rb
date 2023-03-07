# frozen_string_literal: true

module Communes
  class ObjetCardComponent < ViewComponent::Base
    include ObjetHelper

    def initialize(objet, commune:, recensement: nil, badges: nil)
      @objet = objet
      @recensement = recensement
      @commune = commune
      @badges = badges
      super
    end

    def call
      render ::ObjetCardComponent.new(objet, commune:, badges:, main_photo:, path:)
    end

    private

    attr_reader :objet, :recensement, :commune

    delegate :dossier, to: :recensement, allow_nil: true

    def path
      commune_objet_path(commune, objet)
    end

    def badges
      @badges ||= [recensement_badge, analyse_notes_badge].compact
    end

    def main_photo
      return if recensement&.photos.blank?

      Photo.new \
        url: recensement&.photos&.first&.variant(:medium),
        description: "Photo de recensement de l’objet #{objet.nom}"
    end

    def badge_struct
      Struct.new(:color, :text)
    end

    def recensement_badge
      color, text = objet_recensement_badge_color_and_text(objet)
      badge_struct.new(color, text)
    end

    def analyse_notes_badge
      return nil unless dossier&.rejected?

      badge_struct.new("info", "Commentaires") if recensement&.analyse_notes.present?
    end
  end
end
