# frozen_string_literal: true

FactoryBot.define do
  factory :dossier do
    association :commune
    status { "construction" }

    trait :submitted do
      status { "submitted" }
      notes_commune { "Voici les recensements demandés" }
      submitted_at { 2.days.ago }
    end

    trait :rejected do
      status { "rejected" }
      submitted_at { 1.month.ago }
      rejected_at { 1.day.ago }
      notes_commune { "Voici les recensements demandés" }
      notes_conservateur { "Veuillez prendre de meilleures photos" }
      association :conservateur
    end

    trait :accepted do
      status { "accepted" }
      accepted_at { 2.days.ago }
      notes_conservateur { "Quels beaux tableaux" }
    end
  end
end
