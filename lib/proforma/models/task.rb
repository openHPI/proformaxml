# frozen_string_literal: true

require 'proforma/models/base'
require 'proforma/models/task_file'
require 'proforma/models/test'
require 'proforma/models/model_solution'
require 'proforma/errors'

module Proforma
  class Task < Base
    attr_accessor :title, :description, :internal_description, :proglang, :uuid, :parent_uuid, :language,
      :model_solutions, :files, :tests, :meta_data, :submission_restrictions, :external_resources, :grading_hints

    def initialize(attributes = {})
      super
      self.files = [] if files.nil?
      self.tests = [] if tests.nil?
      self.model_solutions = [] if model_solutions.nil?
      self.meta_data = {} if meta_data.nil?
      # self.submission_restrictions = {} if submission_restrictions.nil?
      # self.external_resources = {} if external_resources.nil?
      # self.grading_hints = {} if grading_hints.nil?
    end

    def all_files
      task_files = files
      model_solution_files = model_solutions.map(&:files).filter(&:present?)
      test_files = tests.map(&:files).filter(&:present?)
      (task_files + model_solution_files + test_files).flatten.uniq
    end
  end
end
