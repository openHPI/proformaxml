# frozen_string_literal: true

def file_fixture(fixture_name)
  path = Pathname.new(File.join(file_fixture_path, fixture_name))

  if path.exist?
    path
  else
    msg = "the directory '%s' does not contain a file named '%s'"
    raise ArgumentError.new(format(msg, file_fixture_path, fixture_name))
  end
end

def file_fixture_path
  RSpec.configuration.send(:file_fixture_path)
end
