# frozen_string_literal: true

require 'nokogiri'

module Proforma
  class Importer
    attr_accessor :doc, :files, :task

    def initialize(xml, files = [])
      self.doc = Nokogiri::XML(File.open(xml))
      self.files = files
      self.task = Task.new
    end

    def perform
      errors = validate
      puts errors
      raise 'voll nicht valide und so' if errors.any?

      @task_node = doc.xpath('/ns:task', 'ns' => XML_NAMESPACE)

      set_meta_data
      task
    end

    private

    def set_meta_data
      # task.title = doc.xpath('/ns:task/ns:title', 'ns' => XML_NAMESPACE).text
      # task.title_description = doc.xpath('/ns:task/ns:description', 'ns' => XML_NAMESPACE).text
      # task.internal_description = doc.xpath('/ns:task/ns:internal-description', 'ns' => XML_NAMESPACE).text
      # task.proglang = doc.xpath('/ns:task/ns:proglang', 'ns' => XML_NAMESPACE).text
      task.title = @task_node.at('title').text
      task.description = @task_node.at('description').text
      task.internal_description = @task_node.at('internal-description').text
      task.proglang = @task_node.at('proglang').text
      # hard_meta_values = %w[submission-restrictions files external-resources model-solutions tests grading-hints]
      # task.description = doc.xpath('/ns:task/ns:description', 'ns' => XML_NAMESPACE).text
    end

    def validate
      Nokogiri::XML::Schema(File.open(SCHEMA_PATH)).validate doc
    end
  end
end
