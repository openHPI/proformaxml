# frozen_string_literal: true

RSpec.describe ProformaXML::ModelSolution do
  it_behaves_like 'mass assignable', %i[id description internal_description]
  it_behaves_like 'collections mass assignable', %i[files]
end
