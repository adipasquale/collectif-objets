# frozen_string_literal: true

FactoryBot.define do
  factory :recensement do
    association :dossier
    objet { association :objet, commune: dossier.commune }
    localisation { Recensement::LOCALISATION_EDIFICE_INITIAL }
    recensable { true }
    edifice_nom { nil }
    etat_sanitaire { Recensement::ETAT_BON }
    securisation { Recensement::SECURISATION_CORRECTE }
    notes { "objet très doux" }
    status { "completed" }

    trait :empty do
      localisation { nil }
      recensable { nil }
      edifice_nom { nil }
      etat_sanitaire { nil }
      securisation { nil }
      notes { nil }
    end

    trait :with_photos_mocked do
      transient do
        photos_count { 1 }
        photos_start_number { 1 }
      end

      after(:build) do |recensement, evaluator|
        recensement.instance_variable_set(:@photos_count, evaluator.photos_count)
        recensement.instance_variable_set(:@photos_start_number, evaluator.photos_start_number)
        def recensement.photos
          2.times.each_with_index.map do |_, i|
            photo_number = ((@photos_start_number - 1 + i) % 3) + 1
            mock = Struct.new(:path).new("/demo/photos_recensement/photo#{photo_number}.jpg")
            def mock.to_s = path
            def mock.variant(*, **) = path
            mock
          end
        end
      end
    end

    trait :with_photo do
      after(:build) do |recensement|
        recensement.photos.attach(
          io: Rails.root.join("spec/fixture_files/tableau1.jpg").open,
          filename: "tableau1.jpg",
          content_type: "image/jpeg",
          service_name: "test"
        )
      end
    end

    trait :with_photos do
      transient do
        photos_count { 2 }
      end

      after(:build) do |recensement, evaluator|
        evaluator.photos_count.times do |i|
          recensement.photos.attach(
            io: Rails.root.join("spec/fixture_files/tableau#{i + 1}.jpg").open,
            filename: "tableau#{i + 1}.jpg",
            content_type: "image/jpeg",
            service_name: "test"
          )
        end
      end
    end

    trait :disparu do
      recensable { false }
      localisation { Recensement::LOCALISATION_ABSENT }
      etat_sanitaire { nil }
      securisation { nil }
    end

    trait :deplace do
      localisation { Recensement::LOCALISATION_AUTRE_EDIFICE }
      edifice_nom { "Autre édifice" }
    end

    trait :en_peril do
      etat_sanitaire { Recensement::ETAT_PERIL }
    end

    trait :examiné do
      association :dossier, :examiné
      analysed_at { 1.minute.ago }
      conservateur
    end

    trait :supprimé do
      deleted_at { Time.zone.now }
      status { "deleted" }
      deleted_reason { "objet-devenu-hors-scope" }
      objet { nil }
      deleted_objet_snapshot { attributes_for(:objet) }
    end

    factory :recensement_examiné, traits: [:examiné]
  end
end
