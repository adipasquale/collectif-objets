# frozen_string_literal: true

class Commune < ApplicationRecord
  belongs_to :departement, foreign_key: :departement_code, inverse_of: :communes

  include Communes::IncludeCountsConcern

  include AASM
  aasm(column: :status, timestamps: true) do
    state :inactive, initial: true, display: "Commune inactive"
    state :started, display: "Recensement démarré"
    state :completed, display: "Recensement terminé"

    event(:start) { transitions from: :inactive, to: :started }
    event(:complete) { transitions from: :started, to: :completed }
    event(:return_to_started) { transitions from: :completed, to: :started }
  end

  has_many :users, dependent: :restrict_with_exception
  has_many(
    :objets,
    foreign_key: :palissy_INSEE,
    primary_key: :code_insee,
    inverse_of: :commune,
    dependent: :restrict_with_exception
  )
  has_many :recensements, through: :objets
  has_many :past_dossiers, class_name: "Dossier", dependent: :nullify
  belongs_to :dossier, optional: true
  has_one_attached :formulaire
  has_many :campaign_recipients, dependent: :destroy
  has_many :active_admin_comments, dependent: :destroy, as: :resource
  has_many :survey_votes, dependent: :nullify

  scope :has_recensements_with_missing_photos, lambda {
    joins(:recensements).merge(Recensement.missing_photos).group(:id)
  }
  scope :recensements_photos_presence_in, lambda { |presence|
    presence ? all : has_recensements_with_missing_photos
  }
  scope :completed, -> { where(status: STATE_COMPLETED) }
  has_many(
    :edifices,
    foreign_key: :code_insee, primary_key: :code_insee,
    inverse_of: :commune, dependent: :restrict_with_exception
  )

  include PgSearch::Model
  pg_search_scope :search_by_nom, against: :nom, using: { tsearch: { prefix: true } }
  accepts_nested_attributes_for :dossier, :users

  validate do |commune|
    next if commune.nom.blank? || commune.nom == commune.nom.strip

    errors.add(:nom, :invalid, message: "le nom contient des espaces en trop")
  end

  def self.ransackable_scopes(_auth_object = nil)
    [:recensements_photos_presence_in]
  end

  def self.status_value_counts
    group(:status)
      .select("status, count(id) as communes_count")
      .map { [_1.status, _1.communes_count] }
      .to_h
  end

  def active?
    !inactive?
  end

  def can_complete?
    started? && all_objets_recensed?
  end

  def all_objets_recensed?
    objets.all?(&:recensement?)
  end

  def to_s
    "#{nom} (#{code_insee})"
  end

  def highlighted_objet
    # used in campaigns
    Objet.select_best_objet_in_list(objets.where.not(palissy_TICO: nil).to_a)
  end

  def ongoing_campaign_recipient
    campaign_recipients.joins(:campaign).where(campaigns: { status: "ongoing" }).first
  end
end
