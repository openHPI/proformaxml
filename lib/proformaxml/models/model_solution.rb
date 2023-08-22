# frozen_string_literal: true

module ProformaXML
  class ModelSolution < Base
    attr_accessor :id, :files, :description, :internal_description

    def initialize(attributes = {})
      super
      self.files = [] if files.nil?
    end
  end
end
