# frozen_string_literal: true

require 'active_support/core_ext/string'
require 'proformaxml/helpers/import_helpers'

module ProformaXML
  class Importer < ServiceBase
    include ProformaXML::Helpers::ImportHelpers

    def initialize(zip:, expected_version: nil)
      super()
      @zip = zip
      @expected_version = expected_version

      xml = filestring_from_zip('task.xml')
      raise PreImportValidationError.new(['no task_xml found']) if xml.blank?

      @doc = Nokogiri::XML(xml, &:noblanks)
      @task = Task.new
    end

    def perform
      version_name_extractor = VersionAndNamespaceExtractor.new doc: @doc
      @pro_ns, @doc_schema_version = version_name_extractor.perform&.values_at(:namespace, :version)

      errors = validate
      raise PreImportValidationError.new(errors.map(&:message)) if errors.any?

      @task_node = @doc.xpath("/#{@pro_ns}:task")

      set_data
      if @doc_schema_version != SCHEMA_VERSION_LATEST
        ProformaXML::TransformTask.call(task: @task, from_version: @doc_schema_version, to_version: SCHEMA_VERSION_LATEST)
      end
      @task
    end

    private

    def filestring_from_zip(filename)
      Zip::File.open(@zip.path) do |zip_file|
        return zip_file.glob(filename).first&.get_input_stream&.read
      end
    end

    def remove_referenced_files
      referenced_files = (@task.tests.map(&:files) + @task.model_solutions.map(&:files)).flatten
      @task.files.reject! {|f| referenced_files.include? f }
    end

    def set_data
      set_base_data
      set_files
      set_model_solutions
      set_tests
      remove_referenced_files
      set_meta_data
      set_extra_data
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
      return if @task_node.xpath("#{@pro_ns}:proglang").text.blank?

      @task.proglang = {name: @task_node.xpath("#{@pro_ns}:proglang").text,
                        version: @task_node.xpath("#{@pro_ns}:proglang").attribute('version').value.presence}.compact
    end

    def set_files
      @task_node.xpath("#{@pro_ns}:files//#{@pro_ns}:file").each {|file_node| add_file file_node }
    end

    def set_tests
      @task_node.xpath("#{@pro_ns}:tests//#{@pro_ns}:test").each {|test_node| add_test test_node }
    end

    def set_model_solutions
      @task_node.xpath("#{@pro_ns}:model-solutions//#{@pro_ns}:model-solution").each do |model_solution_node|
        add_model_solution model_solution_node
      end
    end

    def set_meta_data
      meta_data_node = @task_node.xpath("#{@pro_ns}:meta-data").first
      @task.meta_data = convert_xml_node_to_json(meta_data_node) if meta_data_node.text.present?
    end

    def set_extra_data
      submission_restrictions_node = @task_node.xpath("#{@pro_ns}:submission-restrictions").first
      @task.submission_restrictions = convert_xml_node_to_json(submission_restrictions_node) unless submission_restrictions_node.nil?
      external_resources_node = @task_node.xpath("#{@pro_ns}:external-resources").first
      @task.external_resources = convert_xml_node_to_json(external_resources_node) unless external_resources_node.nil?
      grading_hints_node = @task_node.xpath("#{@pro_ns}:grading-hints").first
      @task.grading_hints = convert_xml_node_to_json(grading_hints_node) unless grading_hints_node.nil?
    end

    def add_model_solution(model_solution_node)
      model_solution = ModelSolution.new
      model_solution.id = model_solution_node.attributes['id'].value
      model_solution.files = files_from_filerefs(model_solution_node.xpath("#{@pro_ns}:filerefs"))
      set_value_from_xml(object: model_solution, node: model_solution_node, name: 'description')
      set_value_from_xml(object: model_solution, node: model_solution_node, name: 'internal-description')
      @task.model_solutions << model_solution
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
        filerefs_node.xpath("#{@pro_ns}:fileref").each do |fileref_node|
          fileref = fileref_node.attributes['refid'].value
          files << @task.files.detect {|file| file.id == fileref }
        end
      end
    end

    def validate
      ProformaXML::Validator.call(doc: @doc, expected_version: @expected_version)
    end
  end
end
