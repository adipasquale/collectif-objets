# frozen_string_literal: true

require "rails_helper"

RSpec.describe Recensement, type: :model do
  describe "validations" do
    subject { recensement.valid? }

    context "from factory" do
      let(:recensement) { build(:recensement) }
      it { should eq true }
    end

    context "without etat_sanitaire" do
      let(:recensement) { build(:recensement, etat_sanitaire: nil) }
      it { should eq false }
    end

    context "autre edifice with edifice_nom" do
      let(:recensement) do
        build(:recensement,
              localisation: Recensement::LOCALISATION_AUTRE_EDIFICE,
              edifice_nom: "blah", autre_commune_code_insee: "01010")
      end
      it { should eq true }
    end

    context "autre edifice without edifice_nom" do
      let(:recensement) { build(:recensement, localisation: Recensement::LOCALISATION_AUTRE_EDIFICE, edifice_nom: nil) }
      it { should eq false }
    end

    context "introuvable" do
      let(:attributes) do
        { localisation: Recensement::LOCALISATION_ABSENT, recensable: false, etat_sanitaire: nil, securisation: nil }
      end

      context "other fields empty" do
        let(:recensement) { build(:recensement, attributes) }
        it do
          expect(recensement.valid?).to eq true
        end
      end

      context "recensable true" do
        let(:recensement) { build(:recensement, attributes.merge(recensable: true)) }
        it { should eq false }
      end

      context "etat_sanitaire filled" do
        let(:recensement) { build(:recensement, attributes.merge(etat_sanitaire: Recensement::ETAT_BON)) }
        it { should eq false }
      end

      context "with existing photo" do
        let(:recensement) { build(:recensement, :with_photo, attributes) }
        it { should eq false }
      end

      context "trouvable with existing photo, updating to introuvable without removing photos" do
        let!(:recensement) { create(:recensement, :with_photo) }
        before { recensement.assign_attributes(attributes) }
        it { should eq false }
      end

      context "with existing photo, updating to remove it" do
        let!(:recensement) { create(:recensement, :with_photo) }
        before { recensement.assign_attributes(attributes.merge(photos: [])) }
        it { should eq true }
      end
    end

    context "recensable" do
      context "when attaching a .jfif" do
        let(:recensement) { build(:recensement, :with_photo, photo_files: ["peinture1.jfif"], recensable: true) }
        it { should eq false }
      end
      context "when attaching a .zip" do
        let(:recensement) { build(:recensement, :with_photo, photo_files: ["archive.zip"], recensable: true) }
        it { should eq false }
      end
      context "when attaching a .pdf" do
        let(:recensement) { build(:recensement, :with_photo, photo_files: ["document.pdf"], recensable: true) }
        it { should eq false }
      end
    end

    context "non recensable" do
      let(:attributes) { { recensable: false, etat_sanitaire: nil, securisation: nil } }

      context "other fields empty" do
        let(:recensement) { build(:recensement, attributes) }
        it { should eq true }
      end

      context "autre edifice with edifice_nom set" do
        let(:recensement) do
          build(:recensement, attributes.merge(localisation: Recensement::LOCALISATION_AUTRE_EDIFICE,
                                               edifice_nom: "autre eglise", autre_commune_code_insee: "01010"))
        end
        it { should eq true }
      end

      context "autre edifice with edifice_nom not set" do
        let(:recensement) do
          build(:recensement,
                attributes.merge(localisation: Recensement::LOCALISATION_AUTRE_EDIFICE, edifice_nom: nil))
        end
        it { should eq false }
      end

      context "etat_sanitaire filled" do
        let(:recensement) { build(:recensement, attributes.merge(etat_sanitaire: Recensement::ETAT_BON)) }
        it { should eq false }
      end

      context "with existing photo" do
        let(:recensement) { build(:recensement, :with_photo, attributes) }
        it { should eq false }
      end

      context "recensable with existing photo, updating to non recensable without removing photos" do
        let!(:recensement) { create(:recensement, :with_photo) }
        before { recensement.assign_attributes(attributes) }
        it { should eq false }
      end

      context "with existing photo, updating to remove it" do
        let!(:recensement) { create(:recensement, :with_photo) }
        before { recensement.assign_attributes(attributes.merge(photos: [])) }
        it { should eq true }
      end
    end
  end

  describe "prevent analyse override equal to original" do
    let!(:recensement) do
      build(:recensement, etat_sanitaire:, analyse_etat_sanitaire:)
    end

    subject do
      recensement.update!(analyse_etat_sanitaire: new_analyse_etat_sanitaire)
      recensement.reload.analyse_etat_sanitaire
    end

    context "trying to set initial override value" do
      let(:etat_sanitaire) { Recensement::ETAT_BON }
      let(:analyse_etat_sanitaire) { nil }
      let(:new_analyse_etat_sanitaire) { Recensement::ETAT_MAUVAIS }
      it { should eq Recensement::ETAT_MAUVAIS }
    end

    context "trying to set initial override value to same as original" do
      let(:etat_sanitaire) { Recensement::ETAT_BON }
      let(:analyse_etat_sanitaire) { nil }
      let(:new_analyse_etat_sanitaire) { Recensement::ETAT_BON }
      it { should eq nil }
    end

    context "trying to change override value" do
      let(:etat_sanitaire) { Recensement::ETAT_BON }
      let(:analyse_etat_sanitaire) { Recensement::ETAT_MOYEN }
      let(:new_analyse_etat_sanitaire) { Recensement::ETAT_MAUVAIS }
      it { should eq Recensement::ETAT_MAUVAIS }
    end

    context "trying to change override value to same as original" do
      let(:etat_sanitaire) { Recensement::ETAT_BON }
      let(:analyse_etat_sanitaire) { Recensement::ETAT_MAUVAIS }
      let(:new_analyse_etat_sanitaire) { Recensement::ETAT_BON }
      it { should eq nil }
    end
  end

  describe "#complete!" do
    subject(:do_complete!) { recensement.complete! }

    context "quand recensable est" do
      let(:etat_sanitaire) { Recensement::ETAT_BON }
      let(:securisation) { Recensement::SECURISATION_CORRECTE }
      let(:localisation) { Recensement::LOCALISATION_EDIFICE_INITIAL }
      let(:recensement) do
        create(:recensement, status: :draft, recensable:, localisation:, etat_sanitaire:, securisation:)
      end

      context "false" do
        let(:recensement) do
          create(:recensement, status: :draft, localisation:, recensable:, etat_sanitaire: nil, securisation: nil)
        end
        let(:recensable) { false }
        it "reste false" do
          do_complete!
          expect(recensement.reload.recensable).to eq recensable
        end
      end
      context "true" do
        let(:recensable) { true }
        it "reste true" do
          do_complete!
          expect(recensement.reload.recensable).to eq recensable
        end
      end
      context "vide" do
        let(:recensable) { nil }
        context "et localisation est" do
          context "LOCALISATION_EDIFICE_INITIAL" do
            let(:localisation) { Recensement::LOCALISATION_EDIFICE_INITIAL }
            it "devient true" do
              do_complete!
              expect(recensement.reload.recensable).to eq true
            end
          end
          context "LOCALISATION_AUTRE_EDIFICE" do
            let(:localisation) { Recensement::LOCALISATION_AUTRE_EDIFICE }
            it "devient true" do
              recensement.edifice_nom = "autre édifice"
              do_complete!
              expect(recensement.reload.recensable).to eq true
            end
          end
          context "LOCALISATION_DEPLACEMENT_AUTRE_COMMUNE" do
            let(:localisation) { Recensement::LOCALISATION_DEPLACEMENT_AUTRE_COMMUNE }
            let(:etat_sanitaire) { nil }
            let(:securisation) { nil }
            it "devient false" do
              recensement.autre_commune_code_insee = 12_345
              recensement.edifice_nom = "autre édifice"
              do_complete!
              expect(recensement.reload.recensable).to eq false
            end
          end
          context "LOCALISATION_DEPLACEMENT_TEMPORAIRE" do
            let(:localisation) { Recensement::LOCALISATION_DEPLACEMENT_TEMPORAIRE }
            let(:etat_sanitaire) { nil }
            let(:securisation) { nil }
            it "devient false" do
              do_complete!
              expect(recensement.reload.recensable).to eq false
            end
          end
          context "LOCALISATION_ABSENT" do
            let(:localisation) { Recensement::LOCALISATION_ABSENT }
            let(:etat_sanitaire) { nil }
            let(:securisation) { nil }
            it "devient false" do
              do_complete!
              expect(recensement.reload.recensable).to eq false
            end
          end
        end
      end
    end

    context "pour une commune started" do
      let!(:commune) { create(:commune, :en_cours_de_recensement) }
      let!(:objet) { create(:objet, commune:) }
      let(:recensement) { create(:recensement, objet:, status: "draft", dossier: commune.dossier) }
      it "change le statut du recensement et réutilise le dossier existant" do
        expect(SendMattermostNotificationJob).to \
          receive(:perform_later).with("recensement_created", { "recensement_id" => an_instance_of(Integer) })
        initial_dossier_count = Dossier.count
        do_complete!
        expect(recensement.reload.status.to_sym).to eq :completed
        expect(recensement.reload.dossier).to be_present
        expect(recensement.reload.dossier.status.to_sym).to eq :construction
        expect(commune.reload.status.to_sym).to eq :started
        expect(commune.reload.dossier).to eq recensement.reload.dossier
        expect(Dossier.count).to eq initial_dossier_count
      end
    end
  end

  describe ".prioritaires" do
    subject { Recensement.prioritaires.count }

    context "aucun recensement prioritaire" do
      let!(:recensement) { create(:recensement) }
      it { should eq 0 }
    end

    context "avec un recensement en peril" do
      let!(:recensement) { create(:recensement, :en_peril) }
      it { should eq 1 }
    end

    context "avec un recensement disparu" do
      let!(:recensement) { create(:recensement, :disparu) }
      it { should eq 1 }
    end
  end

  describe "#destroy_or_soft_delete" do
    let(:commune) { create(:commune, code_insee: "01002") }
    let(:objet) do
      create(
        :objet,
        commune:,
        palissy_REF: "PM02000023",
        palissy_TICO: "grande peinture à l'huile",
        lieu_actuel_code_insee: "01002",
        lieu_actuel_edifice_nom: "église saint-jean"
      )
    end
    let!(:user) { create(:user, commune:) }
    subject { recensement.destroy_or_soft_delete!(reason:, message:) }
    let(:reason) { "objet-devenu-hors-scope" }
    let(:message) { "gros problème de sous-dossier" }

    context "recensement completed" do
      let(:recensement) { create(:recensement, objet:) }
      it "soft deletes and stores reason and message" do
        expect(recensement.reload.deleted_at).to be_nil
        subject
        expect(recensement.reload.deleted_at).to be_within(1.second).of(Time.current)
        expect(recensement.reload.deleted_reason).to eq "objet-devenu-hors-scope"
        expect(recensement.reload.deleted_message).to eq "gros problème de sous-dossier"
        expect(recensement.reload.deleted_objet_snapshot["palissy_REF"]).to eq "PM02000023"
        expect(recensement.reload.deleted_objet_snapshot["palissy_TICO"]).to eq "grande peinture à l'huile"
        expect(recensement.reload.deleted_objet_snapshot["lieu_actuel_code_insee"]).to eq "01002"
        expect(recensement.reload.deleted_objet_snapshot["lieu_actuel_edifice_nom"]).to eq "église saint-jean"
      end
    end

    context "recensement completed but soft delete reason incorrect" do
      let(:recensement) { create(:recensement, objet:) }
      let(:reason) { "nimporte-quoi" }
      it "does not soft delete at all" do
        expect(recensement.reload.deleted_at).to be_nil
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
        expect(recensement.reload.deleted_at).to be_nil
      end
    end

    context "recensement completed but no soft delete message" do
      let(:recensement) { create(:recensement, objet:) }
      let(:message) { nil }
      it "soft deletes without a message" do
        expect(recensement.reload.deleted_at).to be_nil
        subject
        expect(recensement.reload.deleted_at).to be_within(1.second).of(Time.current)
        expect(recensement.reload.deleted_reason).to eq "objet-devenu-hors-scope"
        expect(recensement.reload.deleted_message).to be_nil
        expect(recensement.reload.deleted_objet_snapshot["palissy_REF"]).to eq "PM02000023"
        expect(recensement.reload.deleted_objet_snapshot["palissy_TICO"]).to eq "grande peinture à l'huile"
        expect(recensement.reload.deleted_objet_snapshot["lieu_actuel_code_insee"]).to eq "01002"
        expect(recensement.reload.deleted_objet_snapshot["lieu_actuel_edifice_nom"]).to eq "église saint-jean"
      end
    end

    context "recensement draft" do
      let(:recensement) { create(:recensement, objet:, status: "draft") }
      it "destroys" do
        expect(recensement.reload.deleted_at).to be_nil
        subject
        expect { recensement.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#nouvelle_commune" do
    let(:commune) { create(:commune) }
    let(:localisation) { Recensement::LOCALISATION_DEPLACEMENT_AUTRE_COMMUNE }
    let(:recensement) { build(:recensement, localisation:, autre_commune_code_insee:) }

    context "when autre_commune_code_insee is set" do
      let(:autre_commune_code_insee) { commune.code_insee }
      it "returns the new commune" do
        expect(recensement.nouvelle_commune).to eq commune
      end
    end
    context "when autre_commune_code_insee is nil" do
      let(:autre_commune_code_insee) { nil }
      it "returns nil" do
        expect(recensement.nouvelle_commune).to eq nil
      end
    end
  end

  describe "#nouvel_edifice" do
    let(:recensement) { build(:recensement, localisation:, edifice_nom:) }
    let(:localisation) { Recensement::LOCALISATION_AUTRE_EDIFICE }

    context "when edifice_nom is set" do
      let(:edifice_nom) { "Nouvel édifice" }
      it "returns the name of the new edifice" do
        expect(recensement.nouvel_edifice).to eq edifice_nom
      end
    end
    context "when edifice_nom is nil" do
      let(:edifice_nom) { nil }
      it "returns nil" do
        expect(recensement.nouvel_edifice).to eq nil
      end
    end
  end

  describe "#nouveau_departement" do
    let(:commune) { create(:commune) }
    let(:localisation) { Recensement::LOCALISATION_DEPLACEMENT_AUTRE_COMMUNE }
    let(:recensement) { build(:recensement, localisation:, autre_commune_code_insee:) }

    context "when autre_commune_code_insee is set" do
      let(:autre_commune_code_insee) { commune.code_insee }
      it "returns the new departement" do
        expect(recensement.nouveau_departement).to eq commune.departement
      end
    end
    context "when autre_commune_code_insee is nil" do
      let(:autre_commune_code_insee) { nil }
      it "returns nil" do
        expect(recensement.nouveau_departement).to eq nil
      end
    end
  end
end
