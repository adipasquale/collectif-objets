# frozen_string_literal: true

class RapportPresenter
  RecensementItem = Struct.new(:recensement, :objet, :presenter, :index)
  FicheItem = Struct.new(:fiche, :recensement_items)

  delegate :commune, :accepted_at, :conservateur, :notes_commune, :notes_conservateur, to: :dossier

  def initialize(dossier)
    @dossier = dossier
  end

  def recensement_items
    ordered_recensements.each_with_index.map do |recensement, index|
      RecensementItem.new(recensement, recensement.objet, RecensementPresenter.new(recensement), index + 1)
    end
  end

  def fiches
    ordered_recensements.map(&:analyse_fiches).flatten.sort.map do |fiche_id|
      FicheItem.new(
        Fiche.load_from_id(fiche_id),
        ordered_recensements.select { _1.analyse_fiches.include?(fiche_id) }
      )
    end
  end

  attr_reader :dossier

  private

  def ordered_recensements
    @ordered_recensements ||= @dossier
      .recensements
      .includes(:objet)
      .order('objets."palissy_EDIF" ASC, objets."palissy_REF"')
  end
end
