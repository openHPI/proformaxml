# frozen_string_literal: true

module Proforma
  class ModelSolution
    attr_accessor :id, :files, :description, :internal_description
    def initialize(id: nil, files: nil, description: nil, internal_description: nil)
      self.id = id
      self.files = files
      self.description = description
      self.internal_description = internal_description
    end
  end
end
