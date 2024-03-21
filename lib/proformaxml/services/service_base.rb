# frozen_string_literal: true

module ProformaXML
  class ServiceBase
    def self.call(**)
      new(**).perform
    end
  end
end
