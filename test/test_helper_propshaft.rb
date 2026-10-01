ENV['RAILS_ENV'] = ENV['RACK_ENV'] = 'test'

require 'test_helper'
require 'dummy_propshaft/config/environment'
require 'rails/test_help'
require 'capybara/rails'

# Compile app/assets/stylesheets/application.scss into app/assets/builds, as
# `bin/rails dartsass:build` (hooked into test:prepare) does in a real app.
require 'dartsass/runner'
system(*Dartsass::Runner.dartsass_compile_command, exception: true)
