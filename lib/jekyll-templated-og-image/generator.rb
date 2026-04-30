require "ferrum"
require "fileutils"
require_relative "config"
require_relative "template_resolver"

module JekyllOgImage
  class Generator < Jekyll::Generator
    safe true
    priority :low

    def generate(site)
      @site = site
      @config = Config.new(site.config)
      @resolver = TemplateResolver.new(@config.template_rules, site.source, @config.layouts_dir, site)
      @output_dir = File.join(site.dest, @config.output_dir)
      @source_dir = File.join(site.source, @config.output_dir)

      all_docs = site.posts.docs + site.pages + site.collections.values.flat_map(&:docs)

      documents = []
      @config.template_rules.each do |rule|
        if (collection = rule["collection"])
          case collection
          when "posts" then documents += site.posts.docs
          when "page"  then documents += site.pages
          else              documents += site.collections[collection]&.docs || []
          end
        elsif (glob = rule["path"])
          documents += all_docs.select { |doc| File.fnmatch(glob, doc.url, File::FNM_PATHNAME) }
        end
      end

      @browser = nil
      documents.uniq.reject { |doc| doc.url.end_with?(".xml", ".csv") }.each do |doc|
        generate_image(doc)
      end
    ensure
      @browser&.quit
    end

    private

    def browser
      @browser ||= Ferrum::Browser.new(headless: true, browser_options: { "font-render-hinting" => "none" }).tap do |b|
        b.resize(width: 1200, height: 630)
      end
    end

    def generate_image(doc)
      slug = slug_for(doc)
      output_path = File.join(@output_dir, "#{slug}.png")
      source_path = File.join(@source_dir, "#{slug}.png")

      if File.exist?(source_path) && !@config.force?
        doc.data["og_image"] = "/#{@config.output_dir}/#{slug}.png"
        return
      end

      log "OG Image:", "Generating #{slug}.png"

      html = @resolver.render(doc, @site.site_payload.merge("page" => doc.to_liquid))
      return log("OG Image:", "Skipping #{slug}") if html.nil?

      FileUtils.mkdir_p(@output_dir)
      browser.go_to("data:text/html;charset=utf-8,#{ERB::Util.url_encode(html)}")
      browser.network.wait_for_idle
      browser.screenshot(path: output_path)

      FileUtils.mkdir_p(@source_dir)
      FileUtils.cp(output_path, source_path)

      @site.static_files << Jekyll::StaticFile.new(
        @site, @site.source, @config.output_dir, "#{slug}.png"
      )

      doc.data["og_image"] = "/#{@config.output_dir}/#{slug}.png"
      log "OG Image:", "Generated #{slug}.png"
    end

    def log(topic, message)
      Jekyll.logger.info(topic, message) unless @config.quiet?
    end

    def slug_for(doc)
      doc.url.gsub("/", "-").gsub(/^-|-$/, "").then { |s| s.empty? ? "index" : s }
    end
  end
end
