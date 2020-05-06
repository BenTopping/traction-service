# frozen_string_literal: true

module Types
  # Mutations.
  class MutationTypes < BaseObject
    # Plates
    field :create_plate_with_ont_samples, mutation: Mutations::CreatePlateWithOntSamplesMutation
  end
end