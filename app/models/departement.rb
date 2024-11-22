# frozen_string_literal: true

class Departement < ApplicationRecord
  include Departement::Activity

  CODES = %w[
    01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 21 22 23 24 25 26 27 28 29 2A 2B 30 31 32 33 34
    35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69
    70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 971 972 973 974 976
  ].freeze

  REGIONS = {
    "Auvergne-Rhône-Alpes" => %w[01 03 07 15 26 38 42 43 63 69 73 74],
    "Bourgogne-Franche-Comté" => %w[21 25 39 58 70 71 89 90],
    "Bretagne" => %w[22 29 35 56],
    "Centre-Val de Loire" => %w[18 28 36 37 41 45],
    "Corse" => %w[2A 2B],
    "Grand Est" => %w[08 10 51 52 54 55 57 67 68 88],
    "Hauts-de-France" => %w[02 59 60 62 80],
    "Ile-de-France" => %w[75 77 78 91 92 93 94 95],
    "Normandie" => %w[14 27 50 61 76],
    "Nouvelle-Aquitaine" => %w[16 17 19 23 24 33 40 47 64 79 86 87],
    "Occitanie" => %w[09 11 12 30 31 32 34 46 48 65 66 81 82],
    "Pays de la Loire" => %w[44 49 53 72 85],
    "Provence-Alpes-Côte d'Azur" => %w[04 05 06 13 83 84],
    "Guadeloupe" => ["971"],
    "Martinique" => ["972"],
    "Guyane" => ["973"],
    "La Réunion" => ["974"],
    "Mayotte" => ["976"]
  }.freeze

  has_many :communes, dependent: :nullify, foreign_key: :departement_code, inverse_of: :departement
  has_many :objets, through: :communes
  has_many :dossiers, through: :communes, source: :dossiers
  has_many :recensements, through: :dossiers
  has_many :photos_attachments, through: :recensements
  has_many :conservateur_roles, dependent: :destroy, foreign_key: :departement_code, inverse_of: :departement
  has_many :conservateurs, through: :conservateur_roles
  has_many :campaigns, dependent: :nullify, foreign_key: :departement_code, inverse_of: :departement
  has_many :pop_exports, dependent: :nullify, foreign_key: :departement_code, inverse_of: :departement
  has_many :pop_exports_memoire, -> { memoire }, class_name: "PopExport", dependent: :nullify,
                                                 foreign_key: :departement_code, inverse_of: :departement
  has_many :pop_exports_palissy, -> { palissy }, class_name: "PopExport", dependent: :nullify,
                                                 foreign_key: :departement_code, inverse_of: :departement

  scope :sorted, -> { order(:code) }

  def self.include_objets_count
    joins(
      %{
        LEFT OUTER JOIN (
          SELECT communes.departement_code, SUM(communes.objets_count) AS objets_count
          FROM communes
          GROUP BY communes.departement_code
        ) b ON b."departement_code" = departements.code
      }
    ).select("departements.*, COALESCE(b.objets_count, 0) AS objets_count")
  end

  def self.parse_from_code_insee(code_insee)
    if code_insee&.length != 5
      # Rails.logger.warn "le code INSEE '#{code_insee}' ne fait pas 5 caractères"
      return nil
    end

    code_insee.starts_with?("97") ? code_insee[0..2] : code_insee[0..1]
  end

  def current_campaign
    campaigns.where.not(status: :draft).find_by("date_lancement <= :today AND date_fin >= :today",
                                                today: Time.zone.today)
  end

  def to_s = [code, nom].join(" - ")
  alias display_name to_s
  def memoire_sequence_name = "memoire_photos_number_#{code}"
  def self.ransackable_attributes(_ = nil) = %w[code]

  def stats = Co::DepartementStats.new(self)
end
