require 'test_helper'
require 'sassc'

class IconsTest < Minitest::Test
  include ::SassEngineSupport

  def setup
    # The wrappers use @forward ... with, which requires Dart Sass.
    skip_unless_sass_can_compile_bootstrap!
  end

  def render(source)
    SassC::Engine.new(
      source,
      load_paths: [File.join(GEM_PATH, 'assets', 'stylesheets')],
      syntax: :scss,
      style: :expanded
    ).render
  end

  def test_bootstrap_icons_compiles
    css = render('@use "bootstrap-icons";')
    assert_includes css, '@font-face'
    assert_includes css, 'bi-alarm'
  end

  def test_bootstrap_icons_is_configurable
    css = render('@use "bootstrap-icons" with ($bootstrap-icons-font-dir: "/fonts");')
    assert_includes css, 'url("/fonts/bootstrap-icons.woff2?'
  end

  # The Sprockets wrapper is covered by the dummy app, which uses
  # bootstrap-icons-sprockets and resolves font-url during precompile.

  def test_propshaft_wrapper_emits_root_relative_urls_without_query
    css = render('@use "bootstrap-icons-propshaft";')
    assert_includes css, 'url("/bootstrap-icons.woff2") format("woff2")'
    assert_includes css, 'url("/bootstrap-icons.woff") format("woff")'
    # A query string would make the CSS font URL differ from preload_link_tag's
    # URL, defeating the preload and downloading the font twice.
    refute_match(/\.woff2?\?/, css)
  end

  def test_propshaft_wrapper_is_configurable
    css = render('@use "bootstrap-icons-propshaft" with ($bootstrap-icons-font-src: url("/x.woff2") format("woff2"));')
    assert_includes css, 'src: url("/x.woff2") format("woff2")'
  end
end
