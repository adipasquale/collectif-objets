# frozen_string_literal: true

class Recensement < ApplicationRecord
  include Recensements::AnalyseConcern
  include Recensements::BooleansConcern

  belongs_to :objet, optional: true
  belongs_to :dossier, optional: true
  belongs_to :pop_export_memoire, class_name: "PopExport", inverse_of: :recensements_memoire, optional: true
  belongs_to :pop_export_palissy, class_name: "PopExport", inverse_of: :recensements_palissy, optional: true
  # À terme, avoir une association de ce genre :
  # belongs_to :autre_edifice, class_name: "Edifice", foreign_key: "edifice_id"
  has_many_attached :photos do |attachable|
    attachable.variant :small, resize_to_limit: [300, 400], saver: { strip: true }
    attachable.variant :medium, resize_to_limit: [800, 800], saver: { strip: true }
  end

  delegate :commune, to: :objet, allow_nil: true
  delegate :departement, to: :objet, allow_nil: true

  include AASM
  aasm column: :status, whiny_persistence: true, timestamps: true do
    state :draft, initial: true, display: "Brouillon"
    state :completed, display: "Complet et validé"
    state :deleted, display: "Archivé"

    event :complete, after: :aasm_after_complete, after_commit: :aasm_after_commit_complete do
      transitions from: :draft, to: :completed
    end
    event :soft_delete, before_transaction: :aasm_before_soft_delete_transaction do
      transitions from: %i[completed], to: :deleted
    end
  end

  LOCALISATION_EDIFICE_INITIAL = "edifice_initial"
  # TODO : renommer en "deplacement_autre_edifice"
  LOCALISATION_AUTRE_EDIFICE = "autre_edifice"
  LOCALISATION_DEPLACEMENT_AUTRE_COMMUNE = "deplacement_autre_commune"
  LOCALISATION_ABSENT = "absent"
  LOCALISATIONS = [LOCALISATION_EDIFICE_INITIAL, LOCALISATION_AUTRE_EDIFICE,
                   LOCALISATION_DEPLACEMENT_AUTRE_COMMUNE, LOCALISATION_ABSENT].freeze

  ETAT_BON = "bon"
  ETAT_MOYEN = "moyen"
  ETAT_MAUVAIS = "mauvais"
  ETAT_PERIL = "peril"
  ETATS = [ETAT_BON, ETAT_MOYEN, ETAT_MAUVAIS, ETAT_PERIL].freeze

  SECURISATION_CORRECTE = "en_securite"
  SECURISATION_MAUVAISE = "en_danger"
  SECURISATIONS = [SECURISATION_CORRECTE, SECURISATION_MAUVAISE].freeze

  validates :objet, presence: true, unless: -> { deleted? } # it is important not to use objet_id here
  validates :objet_id, uniqueness: true, if: -> { objet_id.present? }

  validates :localisation, presence: true, inclusion: { in: LOCALISATIONS }, if: -> { completed? }
  # À faire évoluer : retirer edifice_nom au profit d'un belongs_to: autre_edifice
  validates :edifice_nom, presence: true, if: -> { completed? && autre_edifice? }
  validates :autre_commune_code_insee, format: /\b\d{5}\b/, allow_blank: true
  validates :recensable, inclusion: { in: [true, false] }, if: -> { completed? }
  validates :recensable, inclusion: { in: [false] }, if: -> { completed? && absent? }
  validates :etat_sanitaire, presence: true, inclusion: { in: ETATS }, if: -> { completed? && recensable? }
  validates :securisation, presence: true, inclusion: { in: SECURISATIONS }, if: -> { completed? && recensable? }

  validates :etat_sanitaire, inclusion: { in: [nil] }, if: -> { completed? && !recensable? }
  validates :securisation, inclusion: { in: [nil] }, if: -> { completed? && !recensable? }
  validates :photos, inclusion: { in: [] }, if: -> { completed? && !recensable? && photos.attached? }

  validates :conservateur_id, presence: true, if: -> { completed? && analysed? }

  validates :deleted_at, presence: true, if: -> { deleted? }
  validates :deleted_reason, inclusion: { in: %w[objet-devenu-hors-scope changement-de-commune] }, if: -> { deleted? }

  after_create { RefreshCommuneRecensementRatioJob.perform_later(commune.id) }
  after_destroy { RefreshCommuneRecensementRatioJob.perform_later(commune.id) if commune.present? }

  scope :present_and_recensable, lambda {
    where(
      recensable: true,
      localisation: [LOCALISATION_EDIFICE_INITIAL, LOCALISATION_AUTRE_EDIFICE]
    )
  }
  scope :missing_photos, lambda {
    present_and_recensable.where.missing(:photos_attachments)
  }
  scope :photos_presence_in, ->(presence) { presence ? all : missing_photos }
  scope :absent, -> { where(localisation: LOCALISATION_ABSENT) }
  scope :en_peril, -> { where(RECENSEMENT_EN_PERIL_SQL) }
  scope :prioritaires, -> { where(RECENSEMENT_PRIORITAIRE_SQL) }
  scope :recensable, -> { where(recensable: true) }
  scope :not_recensable, -> { where.not(recensable: true) }
  scope :in_departement, lambda { |departement|
    joins(objet: [:commune]).where(communes: { departement: })
  }
  scope :in_commune, ->(commune) { joins(:objet).where(objets: { commune: }) }
  scope :not_analysed, -> { where(analysed_at: nil) }
  scope :absent_or_recensable, -> { where(recensable: true).or(absent) }
  scope :completed, -> { where(status: "completed") }

  # from https://medium.com/@cathmgarcia/soft-deletion-in-ruby-on-rails-a1d65d0172ab
  default_scope { where(deleted_at: nil) } # DANGER: default scopes are INVISIBLE and can lead to unexpected results
  scope :only_deleted, -> { unscope(where: :deleted_at).where.not(deleted_at: nil) }
  scope :with_deleted, -> { unscope(where: :deleted_at) }

  # L'objet est prioritaire s'il a disparu ou s'il est en péril,
  # jugé par la commune ou le conservateur
  RECENSEMENT_ABSENT_SQL = %("recensements"."localisation" = '#{LOCALISATION_ABSENT}').freeze
  RECENSEMENT_EN_PERIL_SQL = %(("recensements"."etat_sanitaire" = '#{ETAT_PERIL}'
    AND "recensements"."analyse_etat_sanitaire" IS NULL)
    OR "recensements"."analyse_etat_sanitaire" = '#{ETAT_PERIL}').squish.freeze
  RECENSEMENT_PRIORITAIRE_SQL = "#{RECENSEMENT_ABSENT_SQL} OR #{RECENSEMENT_EN_PERIL_SQL}".freeze

  ## Le code suivant semble mort
  SQL_ORDER_PRIORITE = %(
    CASE WHEN (
      #{RECENSEMENT_PRIORITAIRE_SQL}
    ) THEN 0
    ELSE 1
    END).squish.freeze
  scope :order_by_priorite, -> { order(Arel.sql(SQL_ORDER_PRIORITE)) }
  def self.order_by_priorite_array(recensements_arel)
    recensements_arel.to_a.sort_by { prioritaire? ? 0 : 1 }
  end
  ## fin du code qui semble mort

  def aasm_after_complete
    commune.start! if commune.inactive?

    if !commune.dossier&.persisted? || !commune.dossier&.valid?
      raise ActiveRecord::RecordInvalid, "cannot complete recensement before dossier is created"
    end

    update(dossier: commune.dossier)
  end

  def aasm_after_commit_complete
    SendMattermostNotificationJob.perform_later("recensement_created", { "recensement_id" => id })
  end

  accepts_nested_attributes_for :dossier

  def self.etats_sanitaires_value_counts
    group("etat_sanitaire")
      .select("etat_sanitaire, count(recensements.id) as recensements_count")
      .to_h { [_1.etat_sanitaire, _1.recensements_count] }
  end

  def self.possible_values_for(attribute_name)
    if attribute_name.include?("etat_sanitaire")
      ETATS
    elsif attribute_name.include?("securisation")
      SECURISATIONS
    end
  end

  def nom_commune_localisation_objet
    commune_localisation_objet = if autre_commune_code_insee.present?
                                   Commune.find_by(code_insee: autre_commune_code_insee)
                                 else
                                   commune
                                 end

    commune_localisation_objet.presence
  end

  def self.ransackable_scopes(_ = nil) = [:photos_presence_in]

  def photos_presenters
    photos.order(:created_at).map { PhotoPresenter.from_attachment(_1) }
  end

  def destroy_or_soft_delete!(**)
    case status
    when "draft"
      destroy!
    when "completed"
      soft_delete!(**)
    end
  end

  private

  def aasm_before_soft_delete_transaction(reason:, message: nil, objet_snapshot: nil)
    assign_attributes \
      objet_id: nil,
      deleted_reason: reason,
      deleted_message: message.presence,
      deleted_objet_snapshot: objet_snapshot || objet.snapshot_attributes
  end
end
