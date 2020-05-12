# frozen_string_literal: true

module Types
  # Mutations.
  class MutationTypes < BaseObject
    # Ont::Plates
    field :create_plate_with_covid_samples, mutation: Mutations::CreatePlateWithCovidSamplesMutation

    # Ont::Libraries
    field :create_covid_libraries, mutation: Mutations::CreateCovidLibrariesMutation

    # Ont::Runs
    field :create_covid_run,
          'Create a GriION run containing up to five flow cells loaded with Covid libraries.',
          mutation: Mutations::CreateCovidRunMutation
  end
end
