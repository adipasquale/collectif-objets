# frozen_string_literal: true

module Synchronizer
  module Edifices
    class Revision
      def initialize(row)
        @row = row
      end

      def synchronize
        find_edifice
        return unless @edifice

        @edifice.assign_attributes(merimee_REF:, nom:, code_insee:, slug:)
        # merimee_PRODUCTEUR: @row["PRODUCTEUR"],
        return unless @edifice.changed?

        if @edifice.code_insee_was.present? && @edifice.code_insee.nil?
          Sidekiq.logger.warn "edifice #{@identified_by} would lose its code_insee " \
                              "(#{@edifice.code_insee_was} -> #{code_insee})"
          return
        end

        Sidekiq.logger.info "edifice #{@identified_by} changed : #{@edifice.changes}, saving..."
        @edifice.save!
      end

      private

      def merimee_REF = @row["reference"]
      def nom = @row["titre_editorial_de_la_notice"]
      def slug = Edifice.slug_for(@row["titre_editorial_de_la_notice"])

      def code_insee
        # code_insee is a single string value using the CSV but an array using the API 🤷‍♂️
        code_insee = @row["cog_insee_lors_de_la_protection"]
        code_insee.is_a?(Array) ? code_insee[0] : code_insee
      end

      def find_edifice
        raise "missing merimee_REF in #{row.to_h}" if merimee_REF.blank?

        @edifice, @identified_by = find_edifice_by_merimee_REF || find_edifice_by_slug_and_code_insee
      end

      def find_edifice_by_merimee_REF
        edifice = Edifice.find_by(merimee_REF:)
        return unless edifice

        [edifice, { merimee_REF: }]
      end

      def find_edifice_by_slug_and_code_insee
        return if slug.blank? || code_insee.blank?

        edifice = Edifice.find_by(slug:, code_insee:, merimee_REF: nil)
        return unless edifice

        [edifice, { slug:, code_insee: }]
      end
    end
  end
end
