require 'capybara/dsl'
require 'fileutils'
module DummyRailsIntegration
  include Capybara::DSL

  def setup
    super
    cleanup_dummy_rails_files
  end

  def teardown
    super
    cleanup_dummy_rails_files
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end

  def screenshot!
    path = "tmp/#{name}.png"
    full_path = File.join(GEM_PATH, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    page.driver.render(full_path, full: true)
    STDERR.puts "Screenshot saved to #{path}"
  end

  private
  def cleanup_dummy_rails_files
    FileUtils.rm_rf(::Rails.root.join('tmp/cache'), secure: true)
    FileUtils.rm_rf(::Rails.root.join('public/assets'), secure: true)
  end
end
