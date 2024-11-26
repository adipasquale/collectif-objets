# frozen_string_literal: true

require "rails_helper"

RSpec.describe "BordereauPdf" do
  let(:bordereau) { create(:bordereau, :with_recensements) }
  let(:pdf) { bordereau.pdf }

  context "#filename" do
    it "returns the expected filename" do
      expected_filename = "bordereau-#{bordereau.commune.to_s.parameterize}-#{bordereau.edifice.nom.parameterize}.pdf"
      expect(pdf.filename).to eq expected_filename
    end
  end

  context "#to_attachable" do
    it "returns a hash with :content_type, :filename, and :io" do
      expected_keys = [:content_type, :filename, :io]
      attachable = pdf.to_attachable
      expect(attachable.keys.sort).to eq expected_keys
      expect(attachable[:content_type]).to eq Mime[:pdf]
    end
  end
end
