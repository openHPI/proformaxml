# frozen_string_literal: true

module Proforma
  class TaskFile
    attr_accessor :id, :content, :filename, :used_by_grader, :visible, :mimetype, :usage_by_lms

    def initialize(id: nil, content: nil, filename: nil, used_by_grader: nil, visible: nil, mimetype: nil, usage_by_lms: nil)
      self.id = id
      self.content = content
      self.filename = filename
      self.used_by_grader = used_by_grader
      self.visible = visible
      self.mimetype = mimetype
      self.usage_by_lms = usage_by_lms
    end
  end
end
