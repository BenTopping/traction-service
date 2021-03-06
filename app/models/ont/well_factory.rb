# frozen_string_literal: true

# Ont namespace
module Ont
  # WellFactory
  # The factory will build a well and associated request
  # from the input attributes
  class WellFactory
    include ActiveModel::Model

    validate :check_well, :check_request_factories

    #
    # Build a well factory
    #
    # @param attributes [Hash] Hash describing the wells to create
    # @option attributes [Plate] :plate The Plate to associate with the wells
    # @option attributes [Hash] :well_attributes Hash describing the well to create
    # @option attributes [TagSetService] :tag_set_service Pre-loaded set of tags
    #                                    for applying to the wells
    #
    def initialize(attributes = {})
      return unless attributes.key?(:well_attributes) && attributes.key?(:tag_set_service)

      @plate = attributes[:plate]
      @tag_set_service = attributes[:tag_set_service]
      build_well(attributes[:well_attributes])
    end

    def bulk_insert_serialise(bulk_insert_serialiser, **options)
      return false unless options[:validate] == false || valid?

      # No need to validate any lower level objects since validation above has already checked them
      request_data = request_factories.map do |request_factory|
        request_factory.bulk_insert_serialise(bulk_insert_serialiser, validate: false)
      end

      bulk_insert_serialiser.well_data(well, request_data)
    end

    private

    attr_reader :plate, :tag_set_service, :well

    def request_factories
      @request_factories || []
    end

    def build_well(attributes)
      @well = ::Well.new(position: attributes[:position], plate: @plate)
      return unless attributes.key?(:samples)

      tag_set_name = Pipelines::ConstantsAccessor.ont_covid_pcr_tag_set_name
      tag_set_service.load_tag_set(tag_set_name)
      @request_factories = attributes[:samples].map do |sample|
        RequestFactory.new(sample_attributes: sample,
                           tag_ids_by_oligo: tag_set_service.loaded_tag_sets[tag_set_name])
      end
    end

    def check_well
      if well.nil?
        errors.add('well', 'cannot be nil')
        return
      end

      return if well.valid?

      well.errors.each do |k, v|
        errors.add(k, v)
      end
    end

    def check_request_factories
      request_factories.each do |request_factory|
        next if request_factory.valid?

        request_factory.errors.each do |k, v|
          errors.add(k, v)
        end
      end
    end
  end
end
