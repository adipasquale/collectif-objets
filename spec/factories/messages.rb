# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    association :commune
    association :author, factory: :user
    origin { "web" }
    text { "Comment s'appelle l'objet en question ?\nJe ne le trouve pas" }
    automated_mail_name { nil }
    created_at { 1.day.ago }

    trait :from_commune do
      author { commune.user }
    end
  end
end
