require File.expand_path('../boot', __FILE__)

# A minimal app on the default stack of a new Rails app: Propshaft for assets,
# dartsass-rails to compile the stylesheets, and importmap-rails for JavaScript.
require 'rails'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'propshaft'
require 'dartsass-rails'
require 'importmap-rails'
require 'bootstrap'

module DummyPropshaft
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
  end
end
