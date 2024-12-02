# frozen_string_literal: true

FactoryBot.define do
  factory :bordereau_recensement do
    transient do
      sequence(:index, 0)
    end
    bordereau
    recensement do
      bordereau.edifice.objets[index].recensement || build(:recensement, objet: bordereau.edifice.objets[index],
                                                                         dossier: bordereau.dossier)
    end
  end
end
