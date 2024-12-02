# frozen_string_literal: true

class Bordereau < ApplicationRecord
  belongs_to :dossier
  belongs_to :edifice, optional: true

  has_one :commune, through: :dossier
  has_one_attached :file

  has_many :bordereau_recensements, -> { sorted }, dependent: :destroy, inverse_of: :bordereau
  accepts_nested_attributes_for :bordereau_recensements

  validates :edifice, uniqueness: { scope: :dossier_id, on: :create }

  class << self
    def for(commune)
      dossier = commune.dossier
      bordereaux = []
      # Précharge les données des bordereaux, qu'ils soient enregistrés ou à construire, et les recensements
      edifices = commune.edifices.with_objets_classés_ou_inscrits.ordered_by_nom
        .left_joins(:bordereaux)
        .includes(:bordereaux, bordereaux: [:file_attachment, :bordereau_recensements])
        .where("bordereaux.dossier_id = :dossier_id OR bordereaux.id IS NULL", dossier_id: dossier.id)

      edifices.each do |edifice|
        bordereau = edifice.bordereaux.find { |b| b.dossier_id == dossier.id }
        bordereau ||= edifice.bordereaux.build(dossier:, edifice_nom: edifice.nom&.upcase_first)
        bordereau.populate_recensements
        bordereaux << bordereau
      end
      bordereaux
    end
  end

  def nom_edifice = (edifice&.nom || edifice_nom)&.upcase_first
  def pdf = @pdf ||= BordereauPdf.new(self)

  def persist(params)
    save && return if params.empty?

    transaction do
      bordereau_recensements.delete_all
      assign_attributes(params)
      save
    end
  end

  def generate_pdf
    populate_recensements
    file.attach(**pdf.to_attachable)
  end

  def populate_recensements
    existing_recensements = persisted? ? bordereau_recensements.index_by(&:recensement_id) : {}

    recensements
      .left_joins(:bordereau_recensements)
      .preload(:objet) # Impossible d'utiliser include car la requête recensements fait une jointure => AmbiguousColumn
      .includes(
        photos_attachments: { blob: :variant_records },
        bordereau_recensements: { recensement: [:objet, { photos_attachments: { blob: :variant_records } }] }
      )
      .each do |recensement| # rubocop:disable Rails/FindEach
        bordereau_recensements.build(recensement:) unless existing_recensements.key?(recensement.id)
      end

    bordereau_recensements
  end

  private

  def recensements
    dossier.recensements.joins(:objet).merge(Objet.protégés.in_edifice(edifice).order_by_emplacement_and_nom)
  end
end
