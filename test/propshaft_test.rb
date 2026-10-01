require 'test_helper_propshaft'

# Bootstrap in a Rails app on the default stack of `rails new`: Propshaft,
# dartsass-rails and importmap-rails. Runs with test/gemfiles/*_propshaft.gemfile;
# the Sprockets dummy app is covered by rails_test.rb.
class PropshaftTest < ActionDispatch::IntegrationTest
  include ::DummyRailsIntegration

  def test_stylesheet_is_compiled_and_served
    get helpers.stylesheet_path('application')
    assert_response :success
    assert_includes response.body, '.btn'
  end

  def test_importmap_pins_the_bundle
    get helpers.asset_path('bootstrap.bundle.min.js')
    assert_response :success
    assert_equal 'text/javascript', response.media_type
    assert_includes Rails.application.importmap.to_json(resolver: helpers), helpers.asset_path('bootstrap.bundle.min.js')
  end

  def test_icons_font_urls_are_digested_and_match_preload
    get helpers.stylesheet_path('application')
    %w(woff2 woff).each do |format|
      font_path = helpers.asset_path("bootstrap-icons.#{format}")
      assert_match %r{\A/assets/bootstrap-icons-\h+\.#{format}\z}, font_path
      # Exactly the URL that preload_link_tag emits, with no ?hash query string.
      assert_match %r{url\("?#{Regexp.escape(font_path)}"?\) format\("#{format}"\)}, response.body
    end
  end

  def test_visit_root
    visit root_path
    assert_equal 200, page.status_code

    # Set by app/javascript/application.js once Bootstrap is imported and a tooltip shown.
    assert_selector 'body[data-bootstrap="loaded"]', visible: :all
    assert_selector '.tooltip', text: 'Bootstrap via importmaps'

    # The icon font is preloaded and used by the stylesheet, so it must be
    # downloaded exactly once (a URL mismatch would fetch it twice).
    assert page.evaluate_async_script(<<~JS), 'Bootstrap Icons font did not load'
      const done = arguments[arguments.length - 1];
      document.fonts.load('1em bootstrap-icons').then(fonts => done(fonts.length > 0), () => done(false));
    JS
    font_requests = page.driver.browser.network.traffic.map { |t| t.request.url }.grep(/bootstrap-icons.*\.woff2/)
    assert_equal 1, font_requests.size, "Expected one icon font request, got: #{font_requests.inspect}"

    screenshot!
  end

  def test_precompile
    # Precompile in a separate process, like `bin/rails assets:precompile`.
    # In-process, Propshaft's precompile re-encodes its memoized compiled assets
    # as UTF-8, after which its dev server sends a character-count Content-Length
    # for multi-byte files and truncates them (breaking test_visit_root).
    assert system({ 'RAILS_ENV' => 'test' }, RbConfig.ruby, '-S', 'rake', '-f', Rails.root.join('Rakefile').to_s,
                  'assets:precompile', out: File::NULL), 'assets:precompile failed'
    assert Dir.glob(Rails.root.join('public/assets/application-*.css')).any?
    assert Dir.glob(Rails.root.join('public/assets/bootstrap.bundle.min-*.js')).any?
  end

  private

  def helpers
    ApplicationController.helpers
  end
end
