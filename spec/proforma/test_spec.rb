# frozen_string_literal: true

RSpec.describe Proforma::Test do
  it_behaves_like 'mass assignable', %i[id title description internal_description test_type files meta_data]
end
