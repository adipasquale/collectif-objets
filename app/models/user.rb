# frozen_string_literal: true

class User < ApplicationRecord
  devise :timeoutable, timeout_in: 3.months

  belongs_to :commune, optional: true

  accepts_nested_attributes_for :commune

  has_many :session_codes, dependent: :destroy

  attr_accessor :impersonating

  validates :email, presence: true, uniqueness: true

  def to_s = email.split("@")[0]

  def last_session_code = session_codes.order(created_at: :desc).first
end
