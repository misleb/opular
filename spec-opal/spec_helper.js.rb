require 'opal'
require 'opal_ujs'
require 'opal-rspec'
require 'opal-jquery'
require 'opal-browser'
require 'lib'
require 'opular'


RSpec.configure do |config|
  # For now, always use our custom formatter for results
  #config.formatter = Opal::RSpec::Runner.default_formatter

  # Async helpers for specs
  config.include Opal::RSpec::AsyncHelpers

  # Always support expect() and .should syntax (we should not do this really..)
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end


  config.before(:each) do
    $opular = nil
    OpularRB.boot
  end
end

Opal::RSpec::Runner.autorun
