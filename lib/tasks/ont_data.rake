# frozen_string_literal: true

require_relative '../traction_graphql'

namespace :ont_data do
  desc 'Populate the database with ont plates and runs'
  task :create, [:num] => :environment do |_t, args|
    puts '-> Creating ONT data using GraphQL'

    count = args[:num]&.to_i || 5

    # create count plates
    create_plates(count: count)

    # create count plates with libraries
    barcodes = create_plates(count: count)
    create_libraries(barcodes: barcodes)

    # create count plates with libraries and runs
    barcodes = create_plates(count: count)
    create_libraries(barcodes: barcodes)

    # TODO: assumptions are made here
    # probably needs to be a bit more robust
    barcodes.in_groups_of(5).each do |group_of_barcodes|
      library_names = group_of_barcodes.compact.collect { |barcode| "#{barcode}-1" }
      create_runs(library_names: library_names)
    end

    puts
    puts '-> Successfully created all data'
  end

  task destroy: :environment do
    Plate.all.each do |plate|
      plate.destroy if plate.barcode.start_with? 'DEMO-PLATE-'
    end
    [Ont::Request, Ont::Library, Ont::Flowcell, Ont::Run].each(&:destroy_all)
    puts '-> ONT data successfully deleted'
  end
end

### Helper Methods ###

def show_errors(error_lines)
  error_lines.each { |line| puts line }
  exit
end

def submit_create_plate_query(plate_no:, barcode:, wells:)
  puts "-> Creating plate number #{plate_no}"
  result = TractionGraphQL::Client.query(OntPlates::CreatePlate, variables: { barcode: barcode, wells: wells })

  errors_array = result.original_hash['data']['createPlateWithSamples']['errors']
  show_errors ["-> Failed to create plate number #{plate_no}: #{errors_array}"] if errors_array.any?

  puts "-> Succesfully created plate number #{plate_no}"
rescue Errno::ECONNREFUSED
  show_errors ["-> Failed to connect to the Rails server at #{TractionGraphQL::RAILS_ROOT_URI}",
               '   Use the RAILS_ROOT_URI environment variable to specify a different URI']
end

def create_plates(count:)
  puts
  puts "-> Creating #{count} ONT plates"

  plate_no = Plate&.last&.id || 0

  barcodes = create_number_of_plates(count, plate_no)

  puts '-> Successfully created ONT plates'
  barcodes
end

def create_number_of_plates(count, plate_no)
  variables = OntPlates::Variables.new
  tag_set_name = Pipelines::ConstantsAccessor.ont_covid_pcr_tag_set_name

  plate_no.upto(plate_no + count - 1).collect do |i|
    create_plate(i, variables, tag_set_name)
  end
end

def create_plate(plate_no, variables, tag_set_name)
  barcode = "DEMO-PLATE-#{plate_no}"
  submit_create_plate_query(plate_no: plate_no,
                            barcode: barcode,
                            wells: variables.wells(sample_name: "for Demo Plate #{plate_no}",
                                                   tag_set_name: tag_set_name))
  barcode
end

def submit_create_library_query(plate_barcode:)
  puts "-> Creating library for plate with barcode #{plate_barcode}"
  result = TractionGraphQL::Client.query(OntLibraries::CreateLibraries, variables: { plate_barcode: plate_barcode })

  errors_array = result.original_hash['data']['createOntLibraries']['errors']
  if errors_array.any?
    show_errors ["-> Failed to create library for plate with barcode #{plate_barcode}: #{errors_array}"]
  end

  puts "-> Succesfully created library for plate with barcode number #{plate_barcode}"
rescue Errno::ECONNREFUSED
  show_errors ["-> Failed to connect to the Rails server at #{TractionGraphQL::RAILS_ROOT_URI}",
               '   Use the RAILS_ROOT_URI environment variable to specify a different URI']
end

def create_libraries(barcodes:)
  puts
  puts "-> Creating #{barcodes.length} ONT libraries from plates"

  barcodes.each do |barcode|
    submit_create_library_query(plate_barcode: barcode)
  end

  puts '-> Successfully created ONT libraries'
end

def submit_create_run_query(variables:, library_names:)
  flowcells = variables.flowcells(library_names: library_names)
  joined_library_names = library_names.join(', ')
  puts "-> Creating run for libraries with names: #{joined_library_names}"
  result = TractionGraphQL::Client.query(OntRuns::CreateRun, variables: { flowcells: flowcells })

  errors_array = result.original_hash['data']['createOntRun']['errors']
  if errors_array.any?
    show_errors ["-> Failed to create run for libraries with names #{joined_library_names}: #{errors_array}"]
  end

  puts "-> Succesfully created run for libraries with names: #{joined_library_names}"
rescue Errno::ECONNREFUSED
  show_errors ["-> Failed to connect to the Rails server at #{TractionGraphQL::RAILS_ROOT_URI}",
               '   Use the RAILS_ROOT_URI environment variable to specify a different URI']
end

def create_runs(library_names:)
  puts
  puts "-> Creating ONT runs from #{library_names.length} libraries"
  variables = OntRuns::Variables.new

  submit_create_run_query(variables: variables, library_names: library_names)

  puts '-> Successfully created ONT runs'
end
