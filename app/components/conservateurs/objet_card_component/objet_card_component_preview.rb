# frozen_string_literal: true

class Conservateurs::ObjetCardComponent::ObjetCardComponentPreview < ViewComponent::Preview
  def default
    commune = FactoryBot.build(:commune, id: 10).tap(&:readonly!)
    objet = FactoryBot.build(:objet, commune:, id: 20).tap(&:readonly!)
    render Conservateurs::ObjetCardComponent.new(objet, commune:)
  end

  def recensed
    commune = FactoryBot.build(:commune, id: 10).tap(&:readonly!)
    objet = FactoryBot.build(:objet, commune:, id: 20).tap(&:readonly!)
    recensement = FactoryBot.build(:recensement, id: 30).tap(&:readonly!)
    render Conservateurs::ObjetCardComponent.new(objet, recensement:, commune:)
  end

  def analysed
    commune = FactoryBot.build(:commune, id: 10).tap(&:readonly!)
    objet = FactoryBot.build(:objet, commune:, id: 20).tap(&:readonly!)
    recensement = FactoryBot.build(:recensement, id: 30, analysed_at: 2.days.ago).tap(&:readonly!)
    render Conservateurs::ObjetCardComponent.new(objet, recensement:, commune:)
  end
end
