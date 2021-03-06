require 'rails_helper'

RSpec.describe Pacbio::Well, type: :model, pacbio: true do
  context 'uuidable' do
    let(:uuidable_model) { :pacbio_well }
    it_behaves_like 'uuidable'
  end

  context 'row' do
    it 'must have a row' do
      expect(build(:pacbio_well, row: nil)).to_not be_valid
    end
  end

  context 'column' do
    it 'must have a column' do
      expect(build(:pacbio_well, column: nil)).to_not be_valid
    end
  end

  context 'movie time' do
    it 'must be present' do
      expect(build(:pacbio_well, movie_time: nil)).to_not be_valid
    end

    it 'can be a decimal' do
      expect(build(:pacbio_well, movie_time: 0.2).movie_time).to eq(0.2)

    end

    it 'must be within range' do
      expect(build(:pacbio_well, movie_time: 15)).to be_valid
      expect(build(:pacbio_well, movie_time: 31)).to_not be_valid
      expect(build(:pacbio_well, movie_time: 0)).to_not be_valid
    end

  end

  context 'insert size' do

    it 'must be present' do
      expect(build(:pacbio_well, insert_size: nil)).to_not be_valid
    end

    it 'must be within range' do
      expect(build(:pacbio_well, insert_size: 10)).to be_valid
      expect(build(:pacbio_well, insert_size: 5)).to_not be_valid
    end
  end

  it 'must have an on plate loading concentration' do
    expect(build(:pacbio_well, on_plate_loading_concentration: nil)).to_not be_valid
  end

  context 'position' do
    it 'can have a position' do
      expect(build(:pacbio_well, row: 'B', column: '1').position).to eq('B1')
    end
  end

  it 'must have to a plate' do
    expect(build(:pacbio_well, plate: nil)).to_not be_valid
  end

  it 'can have a comment' do
    expect(build(:pacbio_well).comment).to be_present
  end

  it 'can have a summary' do
    well = create(:pacbio_well_with_libraries)
    expect(well.summary).to eq("#{well.sample_names}#{well.comment}")
  end

  context '#libraries?' do
    it 'with libraries' do
      expect(create(:pacbio_well_with_libraries).libraries?).to be_truthy
    end

    it 'no libraries' do
      expect(create(:pacbio_well).libraries?).to_not be_truthy
    end
  end

  context 'Generate HiFi' do
    it 'must have a generate_hifi' do
      expect(build(:pacbio_well, generate_hifi: nil)).to_not be_valid
    end

    it 'must include the correct options' do
      expect(Pacbio::Well.generate_hifis.keys).to eq(["In SMRT Link", "On Instrument", "Do Not Generate"])
    end

    it 'must have a Generate_hifi' do
      expect(create(:pacbio_well, generate_hifi: 0).generate_hifi).to eq "In SMRT Link"
      expect(create(:pacbio_well, generate_hifi: "In SMRT Link").generate_hifi).to eq "In SMRT Link"
      expect(create(:pacbio_well, generate_hifi: 1).generate_hifi).to eq "On Instrument"
      expect(create(:pacbio_well, generate_hifi: "On Instrument").generate_hifi).to eq "On Instrument"
      expect(create(:pacbio_well, generate_hifi: 2).generate_hifi).to eq "Do Not Generate"
      expect(create(:pacbio_well, generate_hifi: "Do Not Generate").generate_hifi).to eq "Do Not Generate"
    end
  end

  context 'ccs_analysis_output' do
    it 'may have ccs_analysis_output' do
      expect(create(:pacbio_well, ccs_analysis_output: 'Yes')).to be_valid
      expect(create(:pacbio_well, ccs_analysis_output: 'No')).to be_valid
      expect(create(:pacbio_well, ccs_analysis_output: '')).to be_valid
    end

    it 'sets ccs_analysis_output to "No" if blank' do
      well = create(:pacbio_well, ccs_analysis_output: '')
      expect(well.ccs_analysis_output).to eq("No")
    end

    it 'ccs_analysis_output stays "Yes" if set to yes' do
      well = create(:pacbio_well, ccs_analysis_output: 'Yes')
      expect(well.ccs_analysis_output).to eq("Yes")
    end
  end

  context 'pre-extension time' do
    it 'is not required' do
      expect(create(:pacbio_well, pre_extension_time: nil)).to be_valid
    end

    it 'can be set' do
      well = build(:pacbio_well, pre_extension_time: 2 )
      expect(well.pre_extension_time).to eq(2)
    end
  end

  context 'libraries' do
    it 'can have one or more' do
      well = create(:pacbio_well)
      well.libraries << create_list(:pacbio_library, 5)
      expect(well.libraries.count).to eq(5)
    end
  end

  context 'request libraries' do

    let(:well)                { create(:pacbio_well) }
    let(:request_libraries)   { create_list(:pacbio_request_library, 2) }

    before(:each) do
      well.libraries << request_libraries.collect(&:library)
    end

    it 'can have one or more' do
      expect(well.request_libraries.length).to eq(2)
    end

    it 'can return a list of sample names' do
      sample_names = well.sample_names.split(':')
      expect(sample_names.length).to eq(2)
      expect(sample_names.first).to eq(request_libraries.first.request.sample_name)

      sample_names = well.sample_names(',').split(',')
      expect(sample_names.length).to eq(2)
      expect(sample_names.first).to eq(request_libraries.first.request.sample_name)
    end

    it 'can return a list of tags' do
      expect(well.tags).to eq(request_libraries.collect(&:tag_id))
    end

  end

  context 'sample sheet mixin' do
    let(:well)                { create(:pacbio_well) }

    it 'includes the Sample Sheet mixin' do
      expect(well.same_barcodes_on_both_ends_of_sequence).to eq true
    end
  end

  context 'template prep kit box barcode' do
    let(:well)   { create(:pacbio_well_with_request_libraries) }

    it 'returns the well libraries template_prep_kit_box_barcode' do
      expect(well.template_prep_kit_box_barcode).to eq 'LK1234567'
    end

    it 'returns default pacbio code when template_prep_kit_box_barcodes are different' do
      well.libraries[1].template_prep_kit_box_barcode = "unique"
      expect(well.template_prep_kit_box_barcode).to eq Pacbio::Well::GENERIC_KIT_BARCODE
    end
  end

  context 'collection?' do
    let(:well)                { create(:pacbio_well) }

    it 'will always be true' do
      expect(well).to be_collection
    end
  end
end
