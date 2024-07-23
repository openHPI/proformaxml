# frozen_string_literal: true

require 'active_support/core_ext/array/wrap'

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
      transform_submission_restrictions_from_2_0_to_2_1 unless @task.submission_restrictions.nil?
      transform_external_resources_from_2_0_to_2_1 unless @task.external_resources.nil?

      @task.model_solutions.filter! {|model_solution| model_solution.id != 'ms-placeholder' }
    end

    def transform_external_resources_from_2_0_to_2_1
      ensure_array(@task.external_resources['external-resources']['external-resource']).each do |external_resource|
        external_resource['@used-by-grader'] = external_resource['@used-by-grader'] || 'false'
        external_resource['@visible'] = external_resource['@visible'] || 'no'
      end
    end

    def transform_submission_restrictions_from_2_0_to_2_1
      ensure_array(@task.submission_restrictions['submission-restrictions']['file-restriction']).each do |fr|
        fr['@use'] = if fr['@required'].nil? || fr.delete('@required') == 'true'
                       'required'
                     else
                       'optional'
                     end
      end
    end

    def transform_from_2_1_to_2_0
      transform_submission_restrictions_from_2_1_to_2_0 unless @task.submission_restrictions.nil?
      transform_external_resources_from_2_1_to_2_0 unless @task.external_resources.nil?
      add_model_solution_placeholder
    end

    def transform_external_resources_from_2_1_to_2_0
      ensure_array(@task.external_resources['external-resources']['external-resource']).each do |external_resource|
        external_resource.delete('@visible')
        external_resource.delete('@usage-by-lms')
        external_resource.delete('@used-by-grader')
      end
    end

    def transform_submission_restrictions_from_2_1_to_2_0
      transform_file_restrictions_from_2_1_to_2_0
      @task.submission_restrictions['submission-restrictions'].delete('description')
      @task.submission_restrictions['submission-restrictions'].delete('internal-description')
    end

    def transform_file_restrictions_from_2_1_to_2_0
      ensure_array(@task.submission_restrictions['submission-restrictions']['file-restriction']).each do |file_restriction|
        file_restriction['@required'] = (file_restriction['@use'].nil? || file_restriction.delete('@use') == 'required').to_s
      end
    end

    # when only one field is present, dachsfisch does not create an array. This method ensure, that we can work with an array
    def ensure_array(data)
      Array.wrap(data)
    end

    def add_model_solution_placeholder
      return if @task.model_solutions&.any?

      file = TaskFile.new(content: '', id: 'ms-placeholder-file', used_by_grader: false, visible: 'no', binary: false)
      model_solution = ModelSolution.new(id: 'ms-placeholder', files: [file])
      @task.model_solutions = [model_solution]
    end
  end
end
