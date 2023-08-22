# frozen_string_literal: true

require 'proformaxml/models/base'
require 'proformaxml/models/task_file'
require 'proformaxml/models/test'
require 'proformaxml/models/model_solution'
require 'proformaxml/errors'

module ProformaXML
  class Task < Base
    attr_accessor :title, :description, :internal_description, :proglang, :uuid, :parent_uuid,
      :language, :model_solutions, :files, :tests, :meta_data

    def initialize(attributes = {})
      super
      self.files = [] if files.nil?
      self.tests = [] if tests.nil?
      self.model_solutions = [] if model_solutions.nil?
      self.meta_data = {} if meta_data.nil?
    end

    def all_files
      task_files = files
      model_solution_files = model_solutions.map(&:files).filter(&:present?)
      test_files = tests.map(&:files).filter(&:present?)
      (task_files + model_solution_files + test_files).flatten.uniq
    end
  end
end
