# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleSheet do

  context 'sample sheet methods' do
    let(:well) { create(:pacbio_well_with_libraries) }

    # rename to whatever the tags are
    context 'barcode_name' do
      xit 'returns a string of library tags when the well has one library' do
      end

      xit 'returns a string of library tags when the well has many libraries' do
      end
    end

    # rename to whatever barcode set is
    context 'barcode_set' do
      xit 'returns a string of the library request tags group id when the well has one library' do
      end

      xit 'returns a string of the library request tags group ids when the well has many libraries' do
      end
    end

    context 'all_libraries_tagged' do
      xit 'returns true if all well libraries are tagged' do
      end

      xit 'returns true is there is only one well library' do
      end

      xit 'returns false if one well library is not tagged' do
      end
    end

    context 'same_barcodes_on_both_ends_of_sequence' do
      xit 'returns true' do
      end
    end

    context 'bio_sample_name' do
      xit 'returns the wells library request sample name when the well has one library' do
      end

      xit 'returns the wells library requests sample names when the well has many libraries' do
      end
    end

  end
end