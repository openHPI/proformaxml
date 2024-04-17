# frozen_string_literal: true

require 'proformaxml/helpers/export_helpers'

module ProformaXML
  class TransformTask < ServiceBase
    def initialize(task:, from_version:, to_version:)
      super()
      @task = task
      @from_version = from_version
      @to_version = to_version
    end

    def perform
      if SCHEMA_VERSIONS.include?(@from_version) && SCHEMA_VERSIONS.include?(@to_version)

        method_name = "transform_from_#{@from_version.tr('.', '_')}_to_#{@to_version.tr('.', '_')}"

        send(method_name) if defined? method_name
      end
    end

    private

    def transform_from_2_0_to_2_1
      if @task.submission_restrictions.present?
        @task.submission_restrictions['submission-restrictions']['file-restriction'].each do |fr|
          fr['@use'] = fr.delete('@required') == 'true' ? 'required' : 'optional'
        end
      end

      @task.model_solutions.filter! {|model_solution| model_solution.id != 'ms-placeholder' }
    end

    def transform_from_2_1_to_2_0
      unless @task.submission_restrictions.nil?
        @task.submission_restrictions['submission-restrictions']['file-restriction'].each do |fr|
          fr['@required'] = (fr.delete('@use') == 'required').to_s
        end
        @task.submission_restrictions['submission-restrictions'].delete('description')
        @task.submission_restrictions['submission-restrictions'].delete('internal-description')
      end
      add_model_solution_placeholder
    end

    def add_model_solution_placeholder
      return if @task.model_solutions&.any?

      file = TaskFile.new(content: '', id: 'ms-placeholder-file', used_by_grader: false, visible: 'no', binary: false)
      model_solution = ModelSolution.new(id: 'ms-placeholder', files: [file])
      @task.model_solutions = [model_solution]
    end
  end
end
