# frozen_string_literal: true

require 'active_support/core_ext/string'

module Proforma
  class Importer
    def initialize(zip)
      @zip = zip

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

    def set_hash_value_if_present(hash:, name:, attributes: nil, value_overwrite: nil)
      raise unless attributes || value_overwrite

      value = value_overwrite || attributes[name.to_s]&.value
      hash[name.underscore.to_sym] = value if value.present?
    end

    def set_value_from_xml(object:, node:, name:, attribute: false, check_presence: true)
      xml_name = name.is_a?(Array) ? name[0] : name

      value = attribute ? node.attribute(xml_name)&.value : node.xpath("xmlns:#{xml_name}").text
      return if check_presence && !value.present?

      set_value(object: object, name: (name.is_a?(Array) ? name[1] : name).underscore, value: value)
    end

    def set_value(object:, name:, value:)
      if object.is_a? Hash
        object[name] = value
      else
        object.send("#{name}=", value)
      end
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

    def embedded_file_attributes(attributes, file_tag)
      shared = shared_file_attributes(attributes, file_tag)
      shared.merge(
        content: shared[:binary] ? Base64.decode64(file_tag.text) : file_tag.text
      ).tap { |hash| hash[:filename] = file_tag.attributes['filename']&.value unless file_tag.attributes['filename']&.value.blank? }
    end

    def attached_file_attributes(attributes, file_tag)
      filename = file_tag.text
      shared_file_attributes(attributes, file_tag).merge(filename: filename,
                                                         content: filestring_from_zip(filename))
    end

    def shared_file_attributes(attributes, file_tag)
      {
        id: attributes['id']&.value,
        used_by_grader: attributes['used-by-grader']&.value == 'true',
        visible: attributes['visible']&.value,
        binary: /-bin-file/.match?(file_tag.name)
      }.tap do |hash|
        set_hash_value_if_present(hash: hash, name: 'usage-by-lms', attributes: attributes)
        set_value_from_xml(object: hash, node: file_tag.parent, name: 'internal-description')
        set_hash_value_if_present(hash: hash, name: 'mimetype', attributes: attributes)
      end
    end

    def add_test(test_node)
      test = Test.new
      set_value_from_xml(object: test, node: test_node, name: 'id', attribute: true, check_presence: false)
      set_value_from_xml(object: test, node: test_node, name: 'title', check_presence: false)
      set_value_from_xml(object: test, node: test_node, name: 'description')
      set_value_from_xml(object: test, node: test_node, name: 'internal-description')
      set_value_from_xml(object: test, node: test_node, name: 'test-type', check_presence: false)
      test.files = test_files_from_test_configuration(test_node.xpath('xmlns:test-configuration'))
      meta_data = test_node.xpath('xmlns:test-configuration').xpath('xmlns:test-meta-data')
      test.meta_data = custom_meta_data(meta_data) unless meta_data.blank?
      @task.tests << test
    end

    def test_files_from_test_configuration(test_configuration_node)
      files_from_filerefs(test_configuration_node.search('filerefs'))
    end

    def files_from_filerefs(filerefs_node)
      [].tap do |files|
        filerefs_node.search('fileref').each do |fileref_node|
          fileref = fileref_node.attributes['refid'].value
          files << @task.files.delete(@task.files.detect { |file| file.id == fileref })
        end
      end
    end

    def custom_meta_data(meta_data_node)
      {}.tap do |meta_data|
        return meta_data if meta_data_node.nil?

        meta_data_node.children.each { |meta_data_tag| meta_data[meta_data_tag.name] = meta_data_tag.children.first.text }
      end
    end

    def validate
      Nokogiri::XML::Schema(File.open(SCHEMA_PATH)).validate @doc
    end
  end
end
