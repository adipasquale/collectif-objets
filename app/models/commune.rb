# frozen_string_literal: true

class Commune < ApplicationRecord
  belongs_to :departement, foreign_key: :departement_code, inverse_of: :communes, counter_cache: true

  include Communes::IncludeStatutGlobalConcern

  include AASM
  aasm column: :status, timestamps: true, whiny_persistence: true do
    state :inactive, initial: true, display: "Commune inactive"
    state :started, display: "Recensement démarré"
    state :completed, display: "Recensement terminé"

    event :start, before: :aasm_before_start do
      transitions from: :inactive, to: :started
    end
    event :complete, after: :aasm_after_complete do
      transitions from: :started, to: :completed
    end
    event :return_to_started, after: :aasm_after_return_to_started do
      transitions from: :completed, to: :started
    end
    event :return_to_inactive do
      transitions from: :completed, to: :inactive
    end
  end

  has_many :users, dependent: :destroy
  has_many(
    :objets,
    foreign_key: :lieu_actuel_code_insee,
    primary_key: :code_insee,
    inverse_of: :commune,
    dependent: nil # leave the objets in the database when the commune is destroyed
  )

  has_many :dossiers, dependent: :restrict_with_error
  has_many :archived_dossiers, -> { archived }, class_name: "Dossier",
                                                dependent: :restrict_with_error,
                                                inverse_of: :commune

  # Pourrait être renommé en dossier_en_cours
  has_one :dossier, -> { where.not(status: :archived) }, dependent: :restrict_with_error, inverse_of: :commune
  has_many :recensements, through: :dossier, source: :recensements
  has_many :campaign_recipients, dependent: :destroy
  has_many :campaigns, through: :campaign_recipients
  has_many :admin_comments, dependent: :destroy, as: :resource
  has_many :survey_votes, dependent: :nullify
  has_many :messages, dependent: :destroy

  scope :with_user, -> { where.associated(:users) }
  scope :with_objets, -> { where.associated(:objets) }
  scope :include_users_count, lambda {
    joins(%(LEFT OUTER JOIN (
              SELECT commune_id, COUNT(users.id) AS users_count
              FROM users
              GROUP BY commune_id
            ) AS nb_users_par_commune ON nb_users_par_commune.commune_id = communes.id).squish)
    .select("communes.*, COALESCE(users_count, 0) AS users_count")
  }
  scope :include_en_peril_and_disparus_count, -> do
    joins(:recensements)
    .select("communes.*,
      COUNT(DISTINCT CASE WHEN #{Recensement::RECENSEMENT_EN_PERIL_SQL} THEN 1 END) AS en_peril_count,
      COUNT(DISTINCT CASE WHEN #{Recensement::RECENSEMENT_ABSENT_SQL} THEN 1 END) AS disparus_count")
    .group("communes.id")
  end

  scope :has_recensements_with_missing_photos, lambda {
    joins(:recensements).merge(Recensement.missing_photos).group(:id)
  }
  scope :recensements_photos_presence_in, lambda { |presence|
    presence ? all : has_recensements_with_missing_photos
  }
  scope :completed, -> { where(status: STATE_COMPLETED) }
  scope :in_departement, ->(code) { where(departement_code: code) if code }

  scope :sort_by_nom, -> { order("communes.nom ASC") }

  # these 2 scopes are a hack for ransack sorting on dossier_status from conservateurs/departements#show
  # from my understanding it should work out of the box with `dossier_status` but it doesn't ¯\_(ツ)_/¯
  # cf https://github.com/activerecord-hackery/ransack/blob/main/lib/ransack/adapters/active_record/context.rb#L211
  scope :sort_by_dossier_status_asc, -> { order("dossiers.status ASC") }
  scope :sort_by_dossier_status_desc, -> { order("dossiers.status DESC") }

  has_many(
    :edifices,
    foreign_key: :code_insee,
    primary_key: :code_insee,
    inverse_of: :commune,
    dependent: :destroy
  )

  accepts_nested_attributes_for :dossier
  accepts_nested_attributes_for :users, allow_destroy: true
  validates_associated :users

  # Le "statut global" est une sorte de fusion des champs status de la commune, du dossier et de l'examen,
  # et permet l'affichage d'un statut unique dans les vues et un filtre facile via Ransack.
  #
  # Pour éviter trop de changements dans le code, il est récupéré à la volée sans modifier le champ "status" actuel.
  # Idéalement, il faudrait utiliser le champ status, en modifiant les états suivants :
  # inactive -> non_recensé, started -> en_cours_de_recensement, completed -> non_examiné
  # et en ajoutant les états en_cours_d_examen et examiné.
  #
  # Ou à minima, ajouter un nouveau champ statut_global, mis à jour comme la commune et en fonction de l'avancement de
  # l'examen côté conservateur.
  STATUT_GLOBAL_NON_RECENSÉ = "Non recensé"
  ORDRE_NON_RECENSÉ = 0
  STATUT_GLOBAL_EN_COURS_DE_RECENSEMENT = "En cours de recensement"
  ORDRE_EN_COURS_DE_RECENSEMENT = 1
  STATUT_GLOBAL_A_EXAMINER = "À examiner"
  ORDRE_A_EXAMINER = 2
  STATUT_GLOBAL_EXAMEN_PRIORITAIRE = "À examiner en priorité"
  ORDRE_EXAMEN_PRIORITAIRE = 3
  STATUT_GLOBAL_EN_COURS_D_EXAMEN = "En cours d'examen"
  ORDRE_EN_COURS_D_EXAMEN = 4
  STATUT_GLOBAL_EXAMINÉ = "Examiné"
  ORDRE_EXAMINÉ = 5

  STATUT_GLOBAUX = [
    STATUT_GLOBAL_NON_RECENSÉ,
    STATUT_GLOBAL_EN_COURS_DE_RECENSEMENT,
    STATUT_GLOBAL_A_EXAMINER,
    STATUT_GLOBAL_EXAMEN_PRIORITAIRE,
    STATUT_GLOBAL_EN_COURS_D_EXAMEN,
    STATUT_GLOBAL_EXAMINÉ
  ].freeze

  def statut_global_texte
    STATUT_GLOBAUX[statut_global]
  end

  # rubocop:disable Metrics/CyclomaticComplexity Épargnons l'âme sensible de Rubocop
  def statut_global
    # Dans le cas où on appelle include_statut_global, le champ existe déjà
    if has_attribute?(:statut_global)
      read_attribute(:statut_global)
    elsif inactive?
      ORDRE_NON_RECENSÉ
    elsif started?
      ORDRE_EN_COURS_DE_RECENSEMENT
    elsif dossier&.accepted?
      ORDRE_EXAMINÉ
    elsif dossier&.replied_automatically?
      ORDRE_A_EXAMINER
    else # dossier.submitted?
      recensements_analysed_count = recensements.where.not(analysed_at: nil).count
      if recensements_analysed_count.zero?
        ORDRE_EXAMEN_PRIORITAIRE
      else # recensements_analysed_count > 0
        ORDRE_EN_COURS_D_EXAMEN
      end
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  validate do |commune|
    next if commune.nom.blank? || commune.nom == commune.nom.strip

    errors.add(:nom, :invalid, message: "le nom contient des espaces en trop")
  end

  before_create { self.inbound_email_token ||= SecureRandom.hex(10) }

  def self.status_value_counts
    group(:status)
      .select("status, count(id) as communes_count")
      .to_h { [_1.status, _1.communes_count] }
  end

  def active?
    !inactive?
  end

  def can_complete?
    started? && all_objets_recensed?
  end

  def all_objets_recensed?
    objets.all?(&:recensement_completed?)
  end

  def to_s
    "#{nom} (#{code_insee})"
  end

  def user = users.first

  def highlighted_objet
    # used in campaigns
    Objet.select_best_objet_in_list(objets.where.not(palissy_TICO: nil).to_a)
  end

  def ongoing_campaign_recipient
    campaign_recipients.joins(:campaign).where(campaigns: { status: "ongoing" }).first
  end

  def can_be_campaign_recipient?
    !started? && users.any? && objets.any?
  end

  def shall_receive_email_objets_verts?(date)
    users.any? &&
      statut_global == Commune::ORDRE_EXAMEN_PRIORITAIRE &&
      !dossier.a_des_objets_prioritaires? &&
      dossier.replied_automatically_at.nil? &&
      dossier.submitted_at.to_date < date - 1.day &&
      !date.on_weekend?
  end

  def archive_dossier
    dossier&.archive! unless dossier&.construction?
    return_to_inactive! if completed?
  end

  def support_email(role:)
    parts = ["mairie", code_insee]
    parts << "conservateur" if role == :conservateur
    parts << inbound_email_token
    "#{parts.join('-')}@#{Rails.configuration.x.inbound_emails_domain}"
  end

  def aasm_before_start
    raise AASM::InvalidTransition, "Commune cannot start if it has a dossier" if dossier.present?

    create_dossier!
  end

  def aasm_after_complete
    dossier.submit! unless dossier.submitted?
  end

  def aasm_after_return_to_started
    dossier.return_to_construction! unless dossier.construction?
  end

  def completed_at
    dossier&.submitted_at
  end

  # -------
  # RANSACK
  # -------

  def self.ransackable_attributes(_ = nil)
    %w[nom code_insee departement_code status objets_count en_peril_count disparus_count statut_global]
  end

  def self.ransackable_scopes(_ = nil) = [:recensements_photos_presence_in]
  def self.ransackable_associations(_ = nil) = %w[dossier dossiers objets]

  ransacker(:nom, type: :string) { Arel.sql("unaccent(nom)") }
end
