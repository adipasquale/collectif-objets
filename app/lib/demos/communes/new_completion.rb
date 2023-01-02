# frozen_string_literal: true

module Demos
  module Communes
    class NewCompletion < Base
      def template = "communes/completions/new"
      def default_variant = "with_photos"

      def perform
        @commune = build(:commune)
        @dossier = build(:dossier, commune: @commune)
        @dossier_completion = DossierCompletion.new(dossier: @dossier)
        @objets = [
          build(
            :objet, :with_palissy_photo, :with_recensement_with_photos_mocked,
            palissy_photo_number: 1,
            recensement_photos_count: 1, recensement_photos_start_number: 1,
            commune: @commune
          ),
          build(
            :objet, :with_palissy_photo, :with_recensement_with_photos_mocked,
            palissy_photo_number: 2,
            recensement_photos_count: 3, recensement_photos_start_number: 2,
            commune: @commune
          )
        ]
      end
    end
  end
end
