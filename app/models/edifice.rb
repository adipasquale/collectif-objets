# frozen_string_literal: true

class Edifice < ApplicationRecord
  belongs_to :commune, foreign_key: :code_insee, primary_key: :code_insee, optional: true, inverse_of: :edifices
  has_many :objets, dependent: :nullify
  has_many :bordereaux, dependent: :nullify

  validates :code_insee, presence: true
  validates :merimee_REF, uniqueness: true, if: -> { merimee_REF.present? }
  validates :slug, uniqueness: { scope: :code_insee }, if: -> { code_insee.present? }

  scope :with_objets, -> { where.not(objets: { id: nil }) }
  scope :with_objets_classés, -> { where.associated(:objets).merge(Objet.classés).group("edifices.id") }
  scope :with_objets_classés_ou_inscrits, lambda {
    where.associated(:objets)
    .merge(Objet.protégés)
    .group("edifices.id")
  }
  scope :ordered_by_nom, -> { order(Arel.sql("LOWER(UNACCENT(edifices.nom))")) }

  scope :preloaded, lambda {
    with_objets.ordered_by_nom.includes(
      objets: [:commune, { recensement: [:photos_attachments, :photos_blobs] }]
    )
  }

  # rubocop:disable Naming/MethodParameterName, Naming/VariableName
  def self.find_or_create_and_synchronize!(merimee_REF:, code_insee:)
    edifice = find_by(merimee_REF:)
    if edifice.nil?
      edifice = create!(merimee_REF:, code_insee:)
      Synchronizer::Edifices::SynchronizeOneJob.perform_now(ref: merimee_REF)
    end
    edifice
  end
  # rubocop:enable Naming/MethodParameterName, Naming/VariableName

  def self.slug_for(nom_edifice)
    return "" if nom_edifice.blank?

    s = nom_edifice.parameterize
    %w[le la l de d du paroissiale et].each { s = s.gsub("-#{_1}-", "-") }
    s = s.sub("-paroissiale-", "")
    s.sub(/-paroissiale$/, "")
    s
  end

  def to_s
    "Édifice #{nom} #{merimee_REF ? "(#{merimee_REF})" : '(sans référence Mérimée)'} - commune #{code_insee}"
  end

  def generate_bordereau!(dossier)
    pdf = Bordereau::Pdf.new(dossier, self)
    bordereau.purge if bordereau.attached?
    bordereau.attach io: pdf.to_io, filename: pdf.filename, content_type: Mime[:pdf]
  end
end
