require 'pathname'
require 'tsort'

class Updater
  module Js
    def update_javascript_assets
      log_status 'Updating javascripts...'
      save_to  = @save_to[:js]
      # Bootstrap 6 ships ES modules only (no UMD bundle, no `window.bootstrap`
      # global). We keep the individual modules and the bundles for importmap
      # pinning; Sprockets `//= require` concatenation no longer applies.
      bootstrap_js_files.each do |name|
        save_file("#{save_to}/#{name}", remove_source_mapping_url(js_dist_contents[name]))
      end
      log_processed "#{bootstrap_js_files * ' '}"

      log_status 'Updating javascript bundles'
      # `bootstrap.{js,min.js}` import @floating-ui/dom and vanilla-calendar-pro
      # as bare specifiers; the `bootstrap.bundle.{js,min.js}` builds inline those
      # dependencies and are fully self-contained (the recommended importmap pin).
      dist_files = %w(bootstrap.js bootstrap.min.js bootstrap.bundle.js bootstrap.bundle.min.js)
      read_files('dist/js', dist_files).each do |name, content|
        path = "assets/javascripts/#{name}"
        save_file path, remove_source_mapping_url(content)
        log_processed path
      end

      vendor_floating_ui
    end

    # Bootstrap 6 depends on @floating-ui/dom (replacing Popper). Vendor a
    # self-contained ESM bundle so apps can pin it via importmaps without a CDN.
    def vendor_floating_ui
      version = floating_ui_version
      log_status "Vendoring @floating-ui/dom@#{version}"
      stub = get_file("https://esm.sh/@floating-ui/dom@#{version}?bundle")
      rel  = stub[/from\s+"([^"]+)"/, 1] or
        raise "Unexpected esm.sh response for @floating-ui/dom@#{version}:\n#{stub}"
      bundle = get_file("https://esm.sh#{rel}")
      path = 'assets/javascripts/floating-ui.js'
      save_file path, bundle
      log_processed path
    end

    def floating_ui_version
      pkg = get_json(file_url 'package.json')
      spec = (pkg['dependencies'] || {})['@floating-ui/dom'] ||
             (pkg['devDependencies'] || {})['@floating-ui/dom'] or
        raise 'Could not find @floating-ui/dom in upstream package.json'
      spec.sub(/\A\D*/, '')
    end

    # The compiled ES modules in `js/dist`, ordered by their import graph.
    # The graph is built from `js/dist` itself (what we ship) rather than
    # `js/src`, which upstream migrated to TypeScript.
    def bootstrap_js_files
      @bootstrap_js_files ||= begin
        imports = Deps.new
        js_dist_contents.each do |name, content|
          # Matches `import ... from "./x.js"`, `export ... from "./x.js"` and
          # side-effect `import "./x.js"`, with either quote style. Only relative
          # imports between Bootstrap's own modules are followed; npm dependencies
          # (e.g. `vanilla-calendar-pro`, `@floating-ui/dom`) are skipped.
          file_imports = content.scan(/\b(?:from|import)\s*["'](\.[^"']+)["']/).flatten(1)
            .map { |f| Pathname.new(name).dirname.join(f).cleanpath.to_s }
            .uniq
          imports.add name, *file_imports
        end
        files = imports.tsort
        raise 'No Bootstrap JavaScript modules found in js/dist' if files.empty?
        files
      end
    end

    def js_dist_contents
      @js_dist_contents ||= read_files('js/dist', get_paths_by_type('js/dist', /\.js$/))
    end

    def remove_source_mapping_url(content)
      content.sub(%r{^//# sourceMappingURL=.*\n?\z}, '')
    end

    class Deps
      include TSort

      def initialize
        @imports = {}
      end

      def add(from, *tos)
        imports = (@imports[from] ||= [])
        imports.push(*tos)
        imports.sort!
      end

      def tsort_each_child(node, &block)
        node_imports = @imports[node]
        if node_imports.nil?
          raise "No imports found for #{node.inspect}\nImports:\n#{@imports.inspect}"
        end
        node_imports.each(&block)
      end

      def tsort_each_node(&block)
        @imports.each_key(&block)
      end
    end
  end
end
