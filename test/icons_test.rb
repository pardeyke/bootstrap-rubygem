require 'test_helper'
require 'sassc'

class IconsTest < Minitest::Test
  def render(entrypoint)
    SassC::Engine.new(
      %(@import "#{entrypoint}";),
      load_paths: [File.join(GEM_PATH, 'assets', 'stylesheets')],
      style: :expanded
    ).render
  end

  def test_bootstrap_icons_compiles
    css = render('bootstrap-icons')
    assert_includes css, '@font-face'
    assert_includes css, 'bi-alarm'
  end

  # The Sprockets wrapper is covered by the dummy app, which imports
  # bootstrap-icons-sprockets and resolves font-url during precompile.

  def test_propshaft_wrapper_emits_root_relative_urls_without_query
    css = render('bootstrap-icons-propshaft')
    assert_includes css, 'url("/bootstrap-icons.woff2") format("woff2")'
    assert_includes css, 'url("/bootstrap-icons.woff") format("woff")'
    # A query string would make the CSS font URL differ from preload_link_tag's
    # URL, defeating the preload and downloading the font twice.
    refute_match(/\.woff2?\?/, css)
  end
end
