# frozen_string_literal: true

module Proforma
  module Base
    include ActiveModel::AttributeAssignment

    def initialize(attributes = {})
      assign_attributes(attributes)
    end
  end
end
