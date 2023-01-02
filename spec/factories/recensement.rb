# frozen_string_literal: true

FactoryBot.define do
  factory :recensement do
    association :objet
    association :user
    association :dossier
    confirmation_sur_place { true }
    localisation { Recensement::LOCALISATION_EDIFICE_INITIAL }
    recensable { true }
    edifice_nom { nil }
    etat_sanitaire { Recensement::ETAT_BON }
    etat_sanitaire_edifice { Recensement::ETAT_MOYEN }
    securisation { Recensement::SECURISATION_CORRECTE }
    notes { "objet très doux" }
    confirmation_pas_de_photos { true }

    trait :empty do
      confirmation_sur_place { nil }
      localisation { nil }
      recensable { nil }
      edifice_nom { nil }
      etat_sanitaire { nil }
      etat_sanitaire_edifice { nil }
      securisation { nil }
      notes { nil }
      confirmation_pas_de_photos { nil }
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
      confirmation_pas_de_photos { false }

      after(:build) do |recensement|
        recensement.photos.attach(
          io: Rails.root.join("spec/fixture_files/tableau1.jpg").open,
          filename: "tableau1.jpg",
          content_type: "image/jpeg",
          service_name: "test"
        )
      end
    end
  end
end
