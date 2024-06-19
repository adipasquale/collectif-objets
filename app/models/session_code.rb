# frozen_string_literal: true

class SessionCode < ApplicationRecord
  EXPIRE_AFTER = 1.day.freeze

  belongs_to :user

  def self.generate_random_code
    length = 6
    rand(10.pow(length - 1)...10.pow(length)).to_s
  end

  def expired?
    created_at < Time.zone.now - EXPIRE_AFTER
  end

  def valid_until = (created_at || Time.zone.now) + EXPIRE_AFTER

  def used? = used_at.present?

  def mark_used! = update!(used_at: Time.zone.now)
end
