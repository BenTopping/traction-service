FactoryBot.define do
  factory :pacbio_plate, class: Pacbio::Plate do
    run { create(:pacbio_run) }

    factory :pacbio_plate_with_wells do
      wells { create_list(:pacbio_well, 5)}
    end
  end
end