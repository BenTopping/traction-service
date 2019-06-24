class CreatePacbioLibraries < ActiveRecord::Migration[5.2]
  def change
    create_table :pacbio_libraries do |t|
      t.float :volume
      t.float :concentration
      t.string :library_kit_barcode
      t.integer :fragment_size
      t.belongs_to :pacbio_tag, index: true
      t.timestamps
    end
  end
end
