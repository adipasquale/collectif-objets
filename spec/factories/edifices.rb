# frozen_string_literal: true

FactoryBot.define do
  factory :edifice do
    transient do
      objets_count { 0 }
    end
    sequence(:merimee_REF) { |n| "PA#{n + 51_001_252}" }
    nom { "église saint jean" }
    merimee_PRODUCTEUR { "Monuments Historiques" }
    code_insee { "51002" }
    slug { |n| "eglise-saint-jean-#{n}" }

    after(:build) do |edifice, evaluator|
      edifice.objets = build_list(:objet, evaluator.objets_count, edifice:, lieu_actuel_code_insee: edifice.code_insee,
                                                                  palissy_EDIF: edifice.nom)
    end
  end
end
