# frozen_string_literal: true

class SessionCode < ApplicationRecord
  LENGTH = 6
  EXPIRE_AFTER = 1.day.freeze

  belongs_to :user
  has_one :commune, through: :user

  scope :used, -> { where.not(used_at: nil) }
  scope :unused, -> { where(used_at: nil) }
  scope :valid, -> { where(created_at: EXPIRE_AFTER.ago..) }
  scope :expired, -> { where(created_at: ..EXPIRE_AFTER.ago) }
  scope :outdated, -> { where(created_at: ..1.month.ago) }

  before_create :generate_code

  delegate :random_code, to: :class

  scope :used, -> { where.not(used_at: nil) }
  scope :unused, -> { where(used_at: nil) }
  scope :valid, -> { unused.where(created_at: EXPIRE_AFTER.ago..) }
  scope :expired, -> { where(created_at: ..EXPIRE_AFTER.ago) }
  scope :outdated, -> { where(created_at: ..1.month.ago) }

  before_create :generate_code

  delegate :random_code, to: :class

  scope :used, -> { where.not(used_at: nil) }
  scope :unused, -> { where(used_at: nil) }
  scope :valid, -> { unused.where(created_at: EXPIRE_AFTER.ago..) }
  scope :expired, -> { where(created_at: ..EXPIRE_AFTER.ago) }
  scope :outdated, -> { where(created_at: ..1.month.ago) }

  before_create :generate_code

  delegate :random_code, to: :class

  def self.random_code
    rand((10.pow(LENGTH - 1))...(10.pow(LENGTH))).to_s
  end

  def self.valid_format?(code)
    /^\d{#{LENGTH}}$/.match? code.to_s.strip
  end

  def expired?
    created_at < Time.zone.now - EXPIRE_AFTER
  end

  def valid_until = (created_at || Time.zone.now) + EXPIRE_AFTER

  def used? = used_at.present?

  def mark_used! = update!(used_at: Time.zone.now)

  private

  def generate_code = self.code = random_code
end
