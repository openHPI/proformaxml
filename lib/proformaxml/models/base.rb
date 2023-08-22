# frozen_string_literal: true

module ProformaXML
  class Base
    include ActiveModel::AttributeAssignment

    def initialize(attributes = {})
      assign_attributes(attributes)
    end
  end
end
