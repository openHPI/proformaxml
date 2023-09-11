# frozen_string_literal: true

require 'active_support/core_ext/string'
require 'proformaxml/helpers/import_helpers'

module ProformaXML
  class Importer
    include ProformaXML::Helpers::ImportHelpers

    def initialize(zip:, expected_version: nil)
      @zip = zip
      @expected_version = expected_version

      xml = filestring_from_zip('task.xml')
      raise PreImportValidationError if xml.nil?

      @doc = Nokogiri::XML(xml, &:noblanks)
      @task = Task.new
    end

    def perform
      errors = validate

      raise PreImportValidationError.new(errors) if errors.any?

      @task_node = @doc.xpath('/xmlns:task')

      set_data
      {task: @task, custom_namespaces: @custom_namespaces}
    end

    private

    def filestring_from_zip(filename)
      Zip::File.open(@zip.path) do |zip_file|
        return zip_file.glob(filename).first&.get_input_stream&.read
      end
    end

    def set_data
      set_namespaces
      set_base_data
      set_files
      set_model_solutions
      set_tests
      set_meta_data
      set_extra_data
    end

    def set_namespaces
      @custom_namespaces = @doc.namespaces.except('xmlns').map {|k, v| {prefix: k[6..], uri: v} }
    end

    def set_base_data
      set_value_from_xml(object: @task, node: @task_node, name: 'title')
      set_value_from_xml(object: @task, node: @task_node, name: 'description')
      set_value_from_xml(object: @task, node: @task_node, name: 'internal-description')
      set_proglang
      set_value_from_xml(object: @task, node: @task_node, name: %w[lang language], attribute: true)
      set_value_from_xml(object: @task, node: @task_node, name: 'parent-uuid', attribute: true)
      set_value_from_xml(object: @task, node: @task_node, name: 'uuid', attribute: true)
    end

    def set_proglang
      return if @task_node.xpath('xmlns:proglang').text.blank?

      @task.proglang = {name: @task_node.xpath('xmlns:proglang').text,
                        version: @task_node.xpath('xmlns:proglang').attribute('version').value.presence}.compact
    end

    def set_files
      @task_node.search('files//file').each {|file_node| add_file file_node }
    end

    def set_tests
      @task_node.search('tests//test').each {|test_node| add_test test_node }
    end

    def set_model_solutions
      @task_node.search('model-solutions//model-solution').each do |model_solution_node|
        add_model_solution model_solution_node
      end
    end

    def set_meta_data
      meta_data_node = @task_node.xpath('xmlns:meta-data')
      @task.meta_data = meta_data(meta_data_node, use_namespace: true) if meta_data_node.text.present?
    end

    def set_extra_data
      submission_restrictions_node = @task_node.xpath('xmlns:submission-restrictions').first
      @task.submission_restrictions = convert_xml_node_to_json(submission_restrictions_node) unless submission_restrictions_node.nil?
      external_resources_node = @task_node.xpath('xmlns:external-resources').first
      @task.external_resources = convert_xml_node_to_json(external_resources_node) unless external_resources_node.nil?
      grading_hints_node = @task_node.xpath('xmlns:grading-hints').first
      @task.grading_hints = convert_xml_node_to_json(grading_hints_node) unless grading_hints_node.nil?
    end

    def add_model_solution(model_solution_node)
      model_solution = ModelSolution.new
      model_solution.id = model_solution_node.attributes['id'].value
      model_solution.files = files_from_filerefs(model_solution_node.search('filerefs'))
      set_value_from_xml(object: model_solution, node: model_solution_node, name: 'description')
      set_value_from_xml(object: model_solution, node: model_solution_node, name: 'internal-description')
      @task.model_solutions << model_solution unless model_solution.files.first&.id == 'ms-placeholder-file'
    end

    def add_file(file_node)
      file_tag = file_node.children.first
      file = nil
      case file_tag.name
        when /embedded-(bin|txt)-file/
          file = TaskFile.new(embedded_file_attributes(file_node.attributes, file_tag))
        when /attached-(bin|txt)-file/
          file = TaskFile.new(attached_file_attributes(file_node.attributes, file_tag))
      end
      @task.files << file
    end

    def add_test(test_node)
      test = Test.new
      set_value_from_xml(object: test, node: test_node, name: 'id', attribute: true, check_presence: false)
      set_value_from_xml(object: test, node: test_node, name: 'title', check_presence: false)
      set_value_from_xml(object: test, node: test_node, name: 'description')
      set_value_from_xml(object: test, node: test_node, name: 'internal-description')
      set_value_from_xml(object: test, node: test_node, name: 'test-type', check_presence: false)
      add_test_configuration(test, test_node)
      @task.tests << test
    end

    def files_from_filerefs(filerefs_node)
      [].tap do |files|
        filerefs_node.search('fileref').each do |fileref_node|
          fileref = fileref_node.attributes['refid'].value
          files << @task.files.delete(@task.files.detect {|file| file.id == fileref })
        end
      end
    end

    def validate
      validator = ProformaXML::Validator.new @doc, @expected_version
      validator.perform
    end
  end
end
