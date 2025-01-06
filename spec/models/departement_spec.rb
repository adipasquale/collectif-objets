# frozen_string_literal: true

require "rails_helper"

describe Departement, type: :model do
  describe "#parse_from_code_insee" do
    subject { Departement.parse_from_code_insee(code_insee) }
    context "Paris" do
      let(:code_insee) { "75056" }
      it { is_expected.to eq "75" }
    end

    context "martinique - fort de france" do
      let(:code_insee) { "97209" }
      it { is_expected.to eq "972" }
    end

    context "09 - Ariège" do
      let(:code_insee) { "09001" }
      it { is_expected.to eq "09" }
    end

    context "ajaccio" do
      let(:code_insee) { "2A004" }
      it { is_expected.to eq "2A" }
    end

    context "nil" do
      let(:code_insee) { nil }
      it { is_expected.to eq nil }
    end
  end

  describe ".with_activity_in(date_range)" do
    let(:departement) { create(:departement) }
    let(:departement2) { create(:departement) }
    let(:commune) { create(:commune, :with_user, departement:) }
    let(:commune2) { create(:commune, :with_user, departement: departement2) }
    let(:date_range) { Time.zone.now.all_week }
    let!(:conservateur) { create(:conservateur, departements: [departement], send_recap: true) }
    let!(:conservateur2) { create(:conservateur, departements: [departement2], send_recap: true) }
    subject(:departements_with_activity) { Departement.with_activity_in(date_range) }

    context "quand une commune a écrit un message" do
      it "liste le département de cette commune" do
        # Message d'une commune du premier département inclus dans la date_range
        create(:message, :from_commune, commune:, created_at: Time.zone.now)
        # Message trop ancien
        create(:message, :from_commune, commune: commune2, created_at: 2.weeks.ago)
        expect(departements_with_activity).to eq({ departement.code => [conservateur.id] })
        expect { departements_with_activity }.not_to exceed_query_limit(1).with(/SELECT/)
      end
    end

    context "quand une commune a transmis un dossier" do
      it "liste le département de cette commune" do
        # Dossier valide
        create(:dossier, :submitted, :with_recensement, commune:, submitted_at: date_range.first + 1.day)
        # Message trop ancien
        create(:dossier, :submitted, :with_recensement, commune: commune2, submitted_at: date_range.first - 1.day)
        expect(departements_with_activity).to eq({ departement.code => [conservateur.id] })
        expect { departements_with_activity }.not_to exceed_query_limit(1).with(/SELECT/)
      end
    end

    context "quand des communes ont envoyé un message et transmis un dossier" do
      it "liste les départements des deux communes" do
        # Message d'une commune du premier département inclus dans la date_range
        create(:message, :from_commune, commune:, created_at: Time.zone.now)
        # Dossier valide
        create(:dossier, :submitted, :with_recensement, commune: commune2, submitted_at: date_range.first + 1.day)
        expect(departements_with_activity).to eq({ departement.code => [conservateur.id],
                                                   departement2.code => [conservateur2.id] })
        expect { departements_with_activity }.not_to exceed_query_limit(1).with(/SELECT/)
      end
    end
  end

  describe "#commune_messages_count(date_range)" do
    let(:departement) { create(:departement) }
    let(:commune) { create(:commune, :with_user, departement:) }
    let(:commune2) { create(:commune, :with_user, departement:) }
    let(:commune_autre_departement) { create(:commune, :with_user) }
    let(:date_range) { Time.zone.now.all_week }
    subject(:commune_messages_count) { departement.commune_messages_count(date_range) }

    context "quand des communes ont écrit des messages" do
      it "indique le nombre de messages par nom de commune" do
        # Message trop ancien
        create(:message, commune:, author: commune.user, created_at: date_range.first - 1.day)
        # Message d'une commune hors département
        create(:message, commune: commune_autre_departement, author: commune_autre_departement.user,
                         created_at: date_range.first + 1.day)
        # Messages attendus
        create(:message, commune:, author: commune.user, created_at: date_range.first + 1.hour)
        create(:message, commune: commune2, author: commune2.user, created_at: date_range.last - 1.hour)
        expect(commune_messages_count).to eq({ commune => 1, commune2 => 1 })
      end
    end
  end

  describe "#commune_dossiers_transmis(date_range)" do
    let(:departement) { create(:departement) }
    let(:commune) { create(:commune, :with_user, departement:) }
    let(:commune2) { create(:commune, :with_user, departement:) }
    let(:commune3) { create(:commune, :with_user) }
    let(:date_range) { Time.zone.now.all_week }
    let(:dossier) { create(:dossier, :submitted, :with_recensement, commune:, submitted_at: date_range.first + 1.day) }
    subject(:commune_dossiers_transmis) { departement.commune_dossiers_transmis(date_range) }

    context "quand des communes ont transmis des dossiers" do
      it "liste les communes" do
        create(:dossier, :submitted, :with_recensement, commune:, submitted_at: date_range.first + 1.day)
        create(:dossier, :submitted, :with_recensement, commune: commune2, submitted_at: date_range.first - 1.day)
        create(:dossier, :submitted, :with_recensement, commune: commune3, submitted_at: date_range.first + 1.day)
        expect(commune_dossiers_transmis).to eq [commune]
      end
      context "avec des objets disparus" do
        it "indique le nombre d'objets disparus par commune" do
          create(:recensement, :disparu, dossier:, objet: create(:objet, commune: dossier.commune))
          expect(commune_dossiers_transmis.first.disparus_count).to eq 1
        end
      end
      context "avec des objets en péril" do
        it "indique le nombre d'objets en péril par commune" do
          create(:recensement, :en_peril, dossier:, objet: create(:objet, commune: dossier.commune))
          expect(commune_dossiers_transmis.first.en_peril_count).to eq 1
        end
      end
    end
  end
end
