# frozen_string_literal: true

module Proforma
  class Test
    include Base
    attr_accessor :id, :title, :description, :internal_description, :test_type, :files, :meta_data
  end
end
