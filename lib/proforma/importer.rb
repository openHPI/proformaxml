# frozen_string_literal: true

require 'active_support/core_ext/string'

module Proforma
  class Importer
    def initialize(zip)
      @zip = zip

      xml = filestring_from_zip('task.xml')
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
        return zip_file.glob(filename).first.get_input_stream.read
      end
    end

    def set_data
      set_meta_data
      set_files
      set_model_solutions
      set_tests
    end

    def set_meta_data
      set_value_if_present(object: @task, node: @task_node, name: 'title')
      set_value_if_present(object: @task, node: @task_node, name: 'description')
      set_value_if_present(object: @task, node: @task_node, name: 'internal-description')
      if @task_node.xpath('xmlns:proglang').text.present? # || @task_node.xpath('xmlns:proglang').attribute('version')&.value&.present?
        @task.proglang = {name: @task_node.xpath('xmlns:proglang').text,
                          version: @task_node.xpath('xmlns:proglang').attribute('version').value}
      end
      set_value_if_present(object: @task, node: @task_node, name: 'lang', attribute: true, overwrite_object_name: 'language')
      set_value_if_present(object: @task, node: @task_node, name: 'parent-uuid', attribute: true)
      set_value_if_present(object: @task, node: @task_node, name: 'uuid', attribute: true)
    end

    def set_value_if_present(object:, node:, name:, attribute: false, overwrite_object_name: nil)
      value = attribute ? node.attribute(name)&.value : node.xpath("xmlns:#{name}").text
      return unless value.present?

      object.send("#{(overwrite_object_name || name).underscore}=", value)
    end

    def set_files
      @task.files = []
      @task_node.search('files//file').each do |file_node|
        add_file file_node
      end
    end

    def set_tests
      @task.tests = []
      @task_node.search('tests//test').each do |test_node|
        add_test test_node
      end
    end

    def set_model_solutions
      @task.model_solutions = []
      @task_node.search('model-solutions//model-solution').each do |model_solution_node|
        add_model_solution model_solution_node
      end
    end

    def add_model_solution(model_solution_node)
      model_solution = ModelSolution.new
      model_solution.id = model_solution_node.attributes['id'].value
      model_solution.files = files_from_filerefs(model_solution_node.search('filerefs'))
      set_value_if_present(object: model_solution, node: model_solution_node, name: 'description')
      set_value_if_present(object: model_solution, node: model_solution_node, name: 'internal-description')
      @task.model_solutions << model_solution
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

    def embedded_file_attributes(attributes, file_tag)
      shared = shared_file_attributes(attributes, file_tag)
      shared.merge(
        content: shared[:binary] ? Base64.decode64(file_tag.text) : file_tag.text
      ).tap { |hash| hash[:filename] = file_tag.attributes['filename']&.value unless file_tag.attributes['filename']&.value.blank? }
    end

    def attached_file_attributes(attributes, file_tag)
      filename = file_tag.text
      shared_file_attributes(attributes, file_tag).merge(
        filename: filename,
        content: filestring_from_zip(filename)
      )
    end

    def shared_file_attributes(attributes, file_tag)
      {
        id: attributes['id']&.value,
        used_by_grader: attributes['used-by-grader']&.value == 'true',
        visible: attributes['visible']&.value,
        binary: /-bin-file/.match?(file_tag.name)
      }.tap do |hash|
        hash[:usage_by_lms] = attributes['usage-by-lms']&.value unless attributes['usage-by-lms']&.value.blank?
        unless file_tag.parent.xpath('xmlns:internal-description')&.text.blank?
          hash[:internal_description] = file_tag.parent.xpath('xmlns:internal-description')&.text
        end
        hash[:mimetype] = attributes['mimetype']&.value unless attributes['mimetype']&.value.blank?
      end
    end

    def add_test(test_node)
      test = Test.new
      test.id = test_node.attributes['id'].value
      test.title = test_node.xpath('xmlns:title').text
      set_value_if_present(object: test, node: test_node, name: 'description')
      set_value_if_present(object: test, node: test_node, name: 'internal-description')
      test.test_type = test_node.xpath('xmlns:test-type').text
      test.files = test_files_from_test_configuration(test_node.xpath('xmlns:test-configuration'))
      unless test_node.xpath('xmlns:test-configuration').xpath('xmlns:test-meta-data').blank?
        test.meta_data = custom_meta_data(test_node.xpath('xmlns:test-configuration').xpath('xmlns:test-meta-data'))
      end
      @task.tests << test
    end

    def test_files_from_test_configuration(test_configuration_node)
      files_from_filerefs(test_configuration_node.search('filerefs'))
    end

    def files_from_filerefs(filerefs_node)
      files = []
      filerefs_node.search('fileref').each do |fileref_node|
        fileref = fileref_node.attributes['refid'].value
        files << @task.files.delete(@task.files.detect { |file| file.id == fileref })
      end
      files
    end

    def custom_meta_data(meta_data_node)
      meta_data = {}
      return meta_data if meta_data_node.nil?

      meta_data_node.children.each do |meta_data_tag|
        meta_data[meta_data_tag.name] = meta_data_tag.children.first.text
      end
      meta_data
    end

    def validate
      Nokogiri::XML::Schema(File.open(SCHEMA_PATH)).validate @doc
    end
  end
end
