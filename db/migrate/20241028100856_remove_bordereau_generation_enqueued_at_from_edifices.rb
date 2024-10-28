class RemoveBordereauGenerationEnqueuedAtFromEdifices < ActiveRecord::Migration[7.1]
  def change
    remove_column :edifices, :bordereau_generation_enqueued_at, :datetime
  end
end
