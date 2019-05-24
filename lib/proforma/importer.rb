# frozen_string_literal: true

module Proforma
  class Importer
    attr_accessor :doc, :files, :task

    def initialize(zip)
      @zip = zip

      xml = filestring_from_zip('task.xml') # use any xml if only one present else use task.xml else break
      @doc = Nokogiri::XML(xml, &:noblanks)
      self.doc = @doc
      @task = Task.new
    end

    def perform
      errors = validate
      puts errors
      raise 'voll nicht valide und so' if errors.any?

      @task_node = @doc.xpath('/ns:task', 'ns' => XML_NAMESPACE)

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
      # set_submission_restrictions
      set_files
      # set_external_resources
      set_model_solutions
      set_tests
      # set_grading_hints
      # hard_meta_values = %w[submission-restrictions files external-resources model-solutions tests grading-hints]
    end

    # describes restrictions to submissions by student - not used in codeharbor -> skipped
    # def set_submission_restrictions
    # end

    def set_meta_data
      @task.title = @task_node.at('title').text unless @task_node.at('title').text.blank?
      @task.description = @task_node.at('description').text unless @task_node.at('description').text.blank?
      @task.internal_description = @task_node.at('internal-description')&.text unless @task_node.at('internal-description')&.text.blank?
      if @task_node.at('proglang').text.present? || @task_node.at('proglang').attributes['version'].value.present?
        @task.proglang = {name: @task_node.at('proglang').text,
                          version: @task_node.at('proglang').attributes['version'].value}
      end
      @task.language = @task_node.attribute('lang').value if @task_node.attribute('lang')&.value&.present?
      @task.parent_uuid = @task_node.attribute('parent-uuid').value if @task_node.attribute('parent-uuid')&.value&.present?
      @task.uuid = @task_node.attribute('uuid').value if @task_node.attribute('uuid')&.value&.present?
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
      model_solution.description = model_solution_node.at('description')&.text unless model_solution_node.at('description')&.text.blank?
      unless model_solution_node.at('internal-description')&.text.blank?
        model_solution.internal_description = model_solution_node.at('internal-description')&.text
      end
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
        unless file_tag.parent.at('internal-description')&.text.blank?
          hash[:internal_description] = file_tag.parent.at('internal-description')&.text
        end
        hash[:mimetype] = attributes['mimetype']&.value unless attributes['mimetype']&.value.blank?
      end
    end

    def add_test(test_node)
      test = Test.new
      test.id = test_node.attributes['id'].value
      test.title = test_node.at('title').text
      test.description = test_node.at('description')&.text unless test_node.at('description')&.text.blank?
      test.internal_description = test_node.at('internal-description')&.text unless test_node.at('description')&.text.blank?
      test.test_type = test_node.at('test-type')&.text
      test.files = test_files_from_test_configuration(test_node.at('test-configuration'))
      unless test_node.at('test-configuration').at('test-meta-data').blank?
        test.meta_data = custom_meta_data(test_node.at('test-configuration').at('test-meta-data'))
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

    # def set_external_resources; end
    # def set_grading_hints; end

    def validate
      Nokogiri::XML::Schema(File.open(SCHEMA_PATH)).validate @doc
    end
  end
end
