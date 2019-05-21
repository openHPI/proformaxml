# frozen_string_literal: true

module Proforma
  class Task
    include Base
    attr_accessor :title, :description, :internal_description, :proglang, :uuid, :parent_uuid,
                  :language, :model_solutions, :files, :tests
    # :submission_restriction, :external_resources, :grading_hints

    def all_files
      task_files = files || []
      model_solution_files = model_solutions&.map(&:files)&.filter(&:present?) || []
      test_files = tests&.map(&:files)&.filter(&:present?) || []
      (task_files + model_solution_files + test_files).flatten.uniq
    end
  end
end
