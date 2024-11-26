# frozen_string_literal: true

FactoryBot.define do
  factory :dossier do
    association :commune
    status { :construction }

    trait :with_recensement do
      recensements { [association(:recensement, dossier: instance, objet: association(:objet, commune:))] }
    end

    trait :with_recensement_examiné do
      recensements { [association(:recensement_examiné)] }
    end

    trait :with_conservateur do
      conservateur
    end

    trait :submitted do
      status { :submitted }
      notes_commune { "Voici les recensements demandés" }
      submitted_at { 2.days.ago }
    end

    trait :accepted do
      conservateur
      status { :accepted }
      accepted_at { 2.days.ago }
      notes_conservateur { "Quels beaux tableaux" }
    end

    trait :examiné do
      accepted
      conservateur
    end

    trait :archived do
      conservateur
      archived_at { 1.day.ago }
      status { :archived }
    end

    factory :dossier_en_cours_dexamen, traits: [:submitted, :with_recensement_examiné]
    factory :dossier_examiné, traits: [:examiné]
  end
end
