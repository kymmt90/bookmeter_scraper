require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

Dir[File.join(File.dirname(__FILE__), "../lib/**/*.rb")].each { |f| require f }
require 'webmock/rspec'
WebMock.disable_net_connect!(:allow => "codeclimate.com")

Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  config.order = :random
  Kernel.srand config.seed

  config.include SpecMacros
end
