# frozen_string_literal: true

require 'active_support/core_ext/string'
require 'proforma/helpers/import_helpers'

module Proforma
  class Importer
    include Proforma::Helpers::ImportHelpers

    def initialize(zip, expected_version = nil)
      @zip = zip
      @expected_version = expected_version

      xml = filestring_from_zip('task.xml')
      raise PreImportValidationError if xml.nil?

      @doc = Nokogiri::XML(xml, &:noblanks)
      @task = Task.new
    end

    def perform
      errors = validate
      puts errors
      raise PreImportValidationError, errors if errors.any?

      @task_node = @doc.xpath('/xmlns:task')

      set_data
      @task
    end

    private

    def filestring_from_zip(filename)
      Zip::File.open(@zip.path) do |zip_file|
        return zip_file.glob(filename).first&.get_input_stream&.read
      end
    end

    def set_data
      set_base_data
      set_files
      set_model_solutions
      set_tests
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
      return unless @task_node.xpath('xmlns:proglang').text.present?

      @task.proglang = {name: @task_node.xpath('xmlns:proglang').text,
                        version: @task_node.xpath('xmlns:proglang').attribute('version').value.presence}.compact
    end

    def set_files
      @task_node.search('files//file').each { |file_node| add_file file_node }
    end

    def set_tests
      @task_node.search('tests//test').each { |test_node| add_test test_node }
    end

    def set_model_solutions
      @task_node.search('model-solutions//model-solution').each do |model_solution_node|
        add_model_solution model_solution_node
      end
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
      if /embedded-(bin|txt)-file/.match? file_tag.name
        file = TaskFile.new(embedded_file_attributes(file_node.attributes, file_tag))
      elsif /attached-(bin|txt)-file/.match? file_tag.name
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
          files << @task.files.delete(@task.files.detect { |file| file.id == fileref })
        end
      end
    end

    def validate
      validator = Proforma::Validator.new @doc, @expected_version
      validator.perform
    end
  end
end
