# frozen_string_literal: true

# Ont namespace
module Ont
  # PlateFactory
  # The factory will build a plate, associated wells and
  # requests from the request parameters
  class PlateFactory
    include ActiveModel::Model

    validate :check_plate, :check_well_factories

    def initialize(attributes = {})
      build_requests(attributes)
    end

    attr_reader :plate

    def bulk_insert_serialise(plate_bulk_inserter, **options)
      return false unless options[:validate] == false || valid?

      well_data = well_factories.map do |well_factory|
        well_factory.bulk_insert_serialise(plate_bulk_inserter, validate: false)
      end
      plate_bulk_inserter.plate_data(plate, well_data)
    end

    private

    attr_reader :well_factories

    def build_requests(attributes)
      wells_attributes = attributes.extract!(:wells)
      build_plate(attributes)
      @well_factories = (wells_attributes[:wells] || []).map do |well_attributes|
        WellFactory.new(plate: plate, well_attributes: well_attributes)
      end
    end

    def build_plate(attributes)
      plate_attributes = attributes.extract!(:barcode)
      @plate = ::Plate.new(plate_attributes)
    end

    def check_plate
      return if plate.valid?

      plate.errors.each do |k, v|
        errors.add(k, v)
      end
    end

    def check_well_factories
      errors.add('wells', 'cannot be empty') if @well_factories.empty?

      well_factories.each do |well_factory|
        next if well_factory.valid?

        well_factory.errors.each do |k, v|
          errors.add(k, v)
        end
      end
    end
  end
end
