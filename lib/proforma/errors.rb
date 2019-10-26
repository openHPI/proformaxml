# frozen_string_literal: true

module Proforma
  class ProformaError < StandardError; end
  class PostGenerateValidationError < ProformaError; end
  class PreImportValidationError < ProformaError; end
end
