require 'rails_helper'

RSpec.describe Pacbio::Library, type: :model, pacbio: true do

  it 'must have a volume' do
    expect(build(:pacbio_library, volume: nil)).to_not be_valid
  end

  it 'must have a concentration' do
    expect(build(:pacbio_library, concentration: nil)).to_not be_valid
  end

  it 'must have a library kit barcode' do
    expect(build(:pacbio_library, library_kit_barcode: nil)).to_not be_valid
  end

  it 'must have a fragment size' do
    expect(build(:pacbio_library, fragment_size: nil)).to_not be_valid
  end

  it 'must have a tag' do
    expect(build(:pacbio_library, tag: nil)).to_not be_valid
  end
  
end