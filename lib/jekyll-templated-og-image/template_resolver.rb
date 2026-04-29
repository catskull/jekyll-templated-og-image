require "liquid"
require "yaml"

module JekyllOgImage
  class TemplateResolver
    DEFAULT_TEMPLATE_PATH = File.expand_path("template/og-image.html", __dir__)

    def initialize(rules, site_source, layouts_dir, site)
      @site_source = site_source
      @layouts_dir = File.expand_path(layouts_dir, site_source)
      @site = site
      @rules = rules.sort_by { |r| r["path"] ? 0 : 1 }
      @cache = {}
    end

    def render(doc, variables)
      path = path_for(doc)
      return nil if path.nil?
      render_file(path, variables)
    end

    private

    def render_file(path, variables)
      front_matter, template = @cache[path] ||= parse_template(path)
      content = template.render!(variables, registers: { site: @site })

      if (layout_name = front_matter["layout"])
        layout_path = File.join(@layouts_dir, "#{layout_name}.html")
        render_file(layout_path, variables.merge(front_matter).merge("content" => content))
      else
        content
      end
    end

    def parse_template(path)
      front_matter, body = parse_front_matter(File.read(path))
      [front_matter, Liquid::Template.parse(body)]
    end

    def path_for(doc)
      @rules.each do |rule|
        next unless matches?(rule, doc)
        return nil if rule["template"] == false
        return File.expand_path(rule["template"], @site_source) if rule["template"]
        return DEFAULT_TEMPLATE_PATH
      end
      DEFAULT_TEMPLATE_PATH
    end

    def matches?(rule, doc)
      if (collection = rule["collection"])
        doc_type(doc) == collection.to_s
      elsif (glob = rule["path"])
        File.fnmatch(glob, doc.url, File::FNM_PATHNAME)
      else
        true
      end
    end

    def doc_type(doc)
      if doc.respond_to?(:collection)
        doc.collection.label
      else
        "page"
      end
    end

    def parse_front_matter(raw)
      if raw =~ /\A---\s*\n(.*?\n?)---\s*\n(.*)/m
        [YAML.safe_load($1) || {}, $2]
      else
        [{}, raw]
      end
    end
  end
end
