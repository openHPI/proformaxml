# frozen_string_literal: true

require 'digest'

module Proforma
  class Task
    include Base
    attr_accessor :title, :description, :internal_description, :proglang, :uuid, :parent_uuid,
                  :language, :model_solutions, :files, :tests

    def initialize(attributes = {})
      super
      self.files = [] if files.nil?
      self.tests = [] if tests.nil?
      self.model_solutions = [] if model_solutions.nil?
    end

    def all_files
      task_files = files
      model_solution_files = model_solutions.map(&:files).filter(&:present?)
      test_files = tests.map(&:files).filter(&:present?)
      (task_files + model_solution_files + test_files).flatten.uniq
    end
  end
end
