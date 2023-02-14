# frozen_string_literal: true

class Communes::ObjetCardComponent::ObjetCardComponentPreview < ViewComponent::Preview
  def default
    commune = FactoryBot.build(:commune, id: 10).tap(&:readonly!)
    objet = FactoryBot.build(:objet, commune:, id: 20).tap(&:readonly!)
    render Communes::ObjetCardComponent.new(objet, commune:)
  end

  def recensed
    commune = FactoryBot.build(:commune, id: 10).tap(&:readonly!)
    objet = FactoryBot.build(:objet, commune:, id: 20).tap(&:readonly!)
    recensement = FactoryBot.build(:recensement).tap(&:readonly!)
    render Communes::ObjetCardComponent.new(objet, recensement:, commune:)
  end
end
