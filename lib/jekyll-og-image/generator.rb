require "ferrum"
require "liquid"
require "fileutils"

module JekyllOgImage
  class Generator < Jekyll::Generator
    safe true
    priority :low

    TEMPLATE_PATH = File.expand_path("template/og-image.html", __dir__)

    def generate(site)
      @site = site
      @template = Liquid::Template.parse(File.read(TEMPLATE_PATH))
      @output_dir = File.join(site.dest, "assets", "og")

      browser = Ferrum::Browser.new(headless: true)
      browser.resize(width: 1200, height: 630)

      documents = site.posts.docs + site.pages
      documents.each do |doc|
        generate_image(browser, doc)
      end
    ensure
      browser&.quit
    end

    private

    def generate_image(browser, doc)
      slug = slug_for(doc)
      output_path = File.join(@output_dir, "#{slug}.png")

      # Skip if image already exists in source
      source_path = File.join(@site.source, "assets", "og", "#{slug}.png")
      return if File.exist?(source_path)

      Jekyll.logger.info "OG Image:", "Generating #{slug}.png"

      title = doc.data["title"] || doc.url
      date = format_date(doc.data["date"])
      tags = Array(doc.data["tags"])

      # Insert zero-width spaces after slashes for URL-style titles
      title = title.gsub("/", "/\u200B") if title.start_with?("/")

      html = @template.render(
        "title" => title,
        "date" => date,
        "tags" => tags
      )

      FileUtils.mkdir_p(@output_dir)

      browser.go_to("data:text/html;charset=utf-8,#{ERB::Util.url_encode(html)}")
      sleep 0.5
      browser.screenshot(path: output_path)

      # Copy to source so it persists across builds
      source_dir = File.join(@site.source, "assets", "og")
      FileUtils.mkdir_p(source_dir)
      FileUtils.cp(output_path, source_path)

      # Add as a static file so Jekyll includes it in the output
      @site.static_files << Jekyll::StaticFile.new(
        @site, @site.source, "assets/og", "#{slug}.png"
      )

      Jekyll.logger.info "OG Image:", "Generated #{slug}.png"
    end

    def slug_for(doc)
      if doc.respond_to?(:slug)
        doc.slug
      else
        doc.url.gsub("/", "-").gsub(/^-|-$/, "").then { |s| s.empty? ? "index" : s }
      end
    end

    def format_date(date)
      return "" unless date
      date = Date.parse(date.to_s) unless date.is_a?(Date) || date.is_a?(Time)
      date.strftime("%B %-d, %Y")
    end
  end
end
