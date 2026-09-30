require 'test_helper_rails'

class RailsTest < ActionDispatch::IntegrationTest
  include ::DummyRailsIntegration
  include ::SassEngineSupport

  def test_visit_root
    skip_unless_sass_can_compile_bootstrap!

    visit root_path
    # ^ will raise on JS errors

    assert_equal 200, page.status_code

    screenshot!
  end

  def test_icons_sprockets_font_urls
    skip_unless_sass_can_compile_bootstrap!

    css = Rails.application.assets['application.css'].to_s
    assert_match %r{url\("?/assets/bootstrap-icons-\h+\.woff2"?\) format\("woff2"\)}, css
    assert_match %r{url\("?/assets/bootstrap-icons-\h+\.woff"?\) format\("woff"\)}, css
  end

  def test_precompile
    skip_unless_sass_can_compile_bootstrap!

    Dummy::Application.load_tasks
    Rake::Task['assets:precompile'].invoke
  end
end
