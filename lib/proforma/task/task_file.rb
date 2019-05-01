# frozen_string_literal: true

module Proforma
  class TaskFile
    attr_accessor :id, :content, :filename, :used_by_grader, :visible, :usage_by_lms, :binary

    def initialize(id: nil, content: nil, filename: nil, used_by_grader: nil, visible: nil, usage_by_lms: nil, binary: nil)
      # mimetype: nil,
      self.id = id
      self.content = content
      self.filename = filename
      self.used_by_grader = used_by_grader
      self.visible = visible
      # self.mimetype = mimetype
      self.usage_by_lms = usage_by_lms
      self.binary = binary
    end
  end
end
