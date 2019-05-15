# frozen_string_literal: true

RSpec.describe Proforma::ModelSolution do
  it_behaves_like 'mass assignable', %i[id files description internal_description]
end
