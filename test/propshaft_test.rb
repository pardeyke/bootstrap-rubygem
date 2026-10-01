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

  def test_visit_root
    visit root_path
    assert_equal 200, page.status_code

    # Set by app/javascript/application.js once Bootstrap is imported and a tooltip shown.
    assert_selector 'body[data-bootstrap="loaded"]', visible: :all
    assert_selector '.tooltip', text: 'Bootstrap via importmaps'
    assert_operator page.evaluate_script('document.styleSheets.length'), :>=, 1

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
