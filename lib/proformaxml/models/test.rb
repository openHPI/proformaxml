# frozen_string_literal: true

module ProformaXML
  class Test < Base
    attr_accessor :id, :title, :description, :internal_description, :test_type, :files, :configuration, :meta_data

    def initialize(attributes = {})
      super
      self.files = [] if files.nil?
    end
  end
end
