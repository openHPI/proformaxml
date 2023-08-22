# frozen_string_literal: true

module ProformaXML
  class TaskFile < Base
    attr_accessor :id, :content, :filename, :used_by_grader, :visible, :usage_by_lms, :binary, :internal_description, :mimetype

    def embed?
      (content&.length || 0) < MAX_EMBEDDED_FILE_SIZE_KB * (2**10)
    end
  end
end
