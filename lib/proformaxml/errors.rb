# frozen_string_literal: true

module ProformaXML
  class ProformaError < StandardError; end

  class PostGenerateValidationError < ProformaError; end

  class PreImportValidationError < ProformaError; end
end
