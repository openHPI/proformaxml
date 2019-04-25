# frozen_string_literal: true

require 'proforma/task/task_file'

module Proforma
  class Test
    attr_accessor :id, :title, :description, :internal_description, :test_type, :files
  end
end
