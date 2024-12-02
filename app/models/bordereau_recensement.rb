# frozen_string_literal: true

class BordereauRecensement < ApplicationRecord
  belongs_to :bordereau, inverse_of: :bordereau_recensements
  belongs_to :recensement, inverse_of: :bordereau_recensements
  has_one :objet, through: :recensement

  scope :sorted, -> { joins(:objet).order('objets."palissy_EMPL", objets."palissy_TICO"') }

  delegate :objet, :absent?, :recensable?, :analyse_etat_sanitaire, :mauvaise_securisation?, to: :recensement
  delegate :nom, :palissy_DPRO, :palissy_REF, :palissy_SCLE, :palissy_CATE, to: :objet

  def denomination
    [nom, époque, catégorie].compact_blank.join("\n")
  end

  def époque = palissy_SCLE ? palissy_SCLE.split(";").compact_blank.join(", ") : ""
  def catégorie = palissy_CATE ? palissy_CATE.split(";").compact_blank.join(", ") : ""

  def etat_sanitaire
    if absent?
      "objet introuvable"
    elsif !recensable?
      "objet non recensable"
    elsif analyse_etat_sanitaire.present?
      analyse_etat_sanitaire
    else
      recensement.etat_sanitaire
    end
  end

  def photo
    if (variant = recensement.photos&.first&.variant(:small))
      variant.url
    elsif objet.palissy_photos.present?
      objet.palissy_photos.first["url"].sub(MEMOIRE_PHOTOS_AWS_BASE_URL, MEMOIRE_PHOTOS_BASE_URL)
    else
      "images/illustrations/photo-manquante-pop.png"
    end
  end

  def notes_commune
    super || [nouvel_edifice, recensement.notes&.upcase_first].compact_blank.join(" ")
  end

  def notes_conservateur
    super || [facile_à_voler, recensement.analyse_notes&.upcase_first].compact_blank.join(" ")
  end

  def nouvel_edifice
    "L’objet a été déplacé : #{recensement.edifice_nom}." if recensement.deplacement_definitif?
  end

  def facile_à_voler
    "L’objet peut être volé facilement." if recensement.mauvaise_securisation?
  end

  def observations
    [
      "<b>Commune :</b> #{notes_commune.presence || '<i>Néant</i>'}",
      "<b>Conservateur :</b> #{notes_conservateur.presence || '<i>Néant</i>'}",
      "<b>Propriétaire :</b> #{notes_proprietaire.presence || '<i>Néant</i>'}",
      "<b>Affectataire :</b> #{notes_affectataire.presence || '<i>Néant</i>'}"
    ].join("\n")
  end

  def to_pdf_cells
    [
      palissy_REF,
      denomination,
      palissy_DPRO, # date de protection
      etat_sanitaire,
      observations,
      pdf_photo
    ]
  end

  def pdf_photo
    blob = recensement.photos.first&.variant(:small)
    return unless blob

    { image: StringIO.new(blob.processed.download), fit: [65, 65] }
  end
end
