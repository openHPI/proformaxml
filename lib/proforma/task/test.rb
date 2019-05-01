# frozen_string_literal: true

module Proforma
  class Test
    attr_accessor :id, :title, :description, :internal_description, :test_type, :files, :meta_data

    def initialize(id: nil, title: nil, description: nil, internal_description: nil, test_type: nil, files: nil, meta_data: nil)
      self.id = id
      self.title = title
      self.description = description
      self.internal_description = internal_description
      self.test_type = test_type
      self.files = files
      self.meta_data = meta_data
    end
  end
end
