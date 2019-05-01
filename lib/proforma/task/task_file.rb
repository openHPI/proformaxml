# frozen_string_literal: true

module Proforma
  class TaskFile
    include Base
    attr_accessor :id, :content, :filename, :used_by_grader, :visible, :usage_by_lms, :binary
  end
end
