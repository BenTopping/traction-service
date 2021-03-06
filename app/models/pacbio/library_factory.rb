# frozen_string_literal: true

# Pacbio namespace
module Pacbio
  # LibraryFactory
  # A library factory can create one library
  # A library can contain one or more requests

  # When there is more than one request
  # Each request must be unique
  # Each request must contain a tag, and each tag must be unique

  # For a set of library attributes:
  # * build a library
  # * build the request libraries
  # * validate the library
  # * validate the request libraries
  # * save the library
  # * save the request libraries
  # * associate request libraries with the library
  class LibraryFactory
    include ActiveModel::Model

    validate :validate_library_and_request_libraries

    # Pacbio::Library
    attr_reader :library

    def initialize(library_attributes)
      build_library(library_attributes)
    end

    delegate :id, to: :library

    # WellFactory::RequestLibraries
    def request_libraries
      @request_libraries ||= []
    end

    def save
      # Validate the Pacbio::Library and its Pacbio::RequestLibrary(s)
      return false unless valid?

      library.save
      request_libraries.save
      @container_material.save

      true
    end

    private

    def build_library(library_attributes)
      @library = create_library(library_attributes)
      request_attributes = library_attributes[:requests]
      build_request_libraries(request_attributes)
    end

    def create_library(library_attributes)
      library_attributes_without_requests = library_attributes.except(:requests)
      library = Pacbio::Library.new(library_attributes_without_requests)
      @container_material = ContainerMaterial.new(container: Tube.new, material: library)
      library
    end

    def build_request_libraries(requests_attributes)
      @request_libraries = RequestLibraries.new(library, requests_attributes)
    end

    def validate_library_and_request_libraries
      unless library.valid?
        library.errors.each do |k, v|
          errors.add(k, v)
        end
      end

      return if request_libraries.valid?

      request_libraries.errors.each do |k, v|
        errors.add(k, v)
      end
    end

    # LibraryFactory::RequestLibraries
    class RequestLibraries
      include ActiveModel::Model

      validate :check_tags, :check_cost_codes, :check_requests_uniq

      attr_reader :library

      def initialize(library, requests_attributes)
        @library = library
        build_request_libraries(requests_attributes)
      end

      # Pacbio::RequestLibrary
      def request_libraries
        @request_libraries ||= []
      end

      def save
        library.request_libraries << request_libraries
      end

      private

      def build_request_libraries(requests_attributes)
        requests_attributes.map do |request_attributes|
          request_libraries << Pacbio::RequestLibrary.new(
            pacbio_request_id: request_attributes[:id],
            tag_id: request_attributes[:tag].try(:[], :id)
          )
        end
      end

      def check_tags
        # Only check tags if there is more than one request library
        return true if request_libraries.length < 2

        # Check every request library has a tag
        tag_ids = request_libraries.map(&:tag_id)
        if tag_ids.any?(&:nil?)
          errors.add('tag', 'must be present')
          return
        end

        # Check no two tags are the same
        tag_ids = request_libraries.map(&:tag_id)
        errors.add('tag', 'is used more than once') if tag_ids.length != tag_ids.uniq.length
      end

      # Check every request has a cost code
      def check_cost_codes
        request_libraries.each do |rl|
          id = rl.pacbio_request_id
          request = Pacbio::Request.find(id)
          errors.add('cost code', 'must be present') if request.cost_code.blank?
        end
      end

      # Check no two requests are the same
      def check_requests_uniq
        request_ids = request_libraries.map(&:pacbio_request_id)
        errors.add('request', 'is used more than once') if
          request_ids.length != request_ids.uniq.length
      end
    end
  end
end
