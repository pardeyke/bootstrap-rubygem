# coding: utf-8

require 'open-uri'
require 'json'
require 'fileutils'

# Updates Bootstrap Icons assets from the bootstrap-icons npm package.
class IconsUpdater
  FILES = {
    'font/bootstrap-icons.scss'        => 'assets/stylesheets/_bootstrap-icons.scss',
    'font/fonts/bootstrap-icons.woff'  => 'assets/fonts/bootstrap-icons.woff',
    'font/fonts/bootstrap-icons.woff2' => 'assets/fonts/bootstrap-icons.woff2'
  }.freeze

  def initialize(version: nil)
    @version = version || latest_version
  end

  def update_icons
    puts "Updating Bootstrap Icons to v#@version"
    FILES.each do |from, to|
      FileUtils.mkdir_p File.dirname(to)
      File.open(to, 'wb') { |f| f.write URI.open(file_url(from)).read }
      puts "  #{to}"
    end
    store_version
  end

  private

  def file_url(path)
    "https://cdn.jsdelivr.net/npm/bootstrap-icons@#@version/#{path}"
  end

  def latest_version
    JSON.parse(URI.open('https://registry.npmjs.org/bootstrap-icons/latest').read)['version']
  end

  # Update version.rb file with BOOTSTRAP_ICONS_VERSION
  def store_version
    path    = 'lib/bootstrap/version.rb'
    content = File.read(path).sub(/BOOTSTRAP_ICONS_VERSION\s*=\s*['"][^'"]*['"]/, "BOOTSTRAP_ICONS_VERSION = '#@version'")
    File.open(path, 'w') { |f| f.write(content) }
  end
end
