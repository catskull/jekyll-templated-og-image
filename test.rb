require "ferrum"
require "liquid"
require "fileutils"

template_path = File.join(__dir__, "lib/jekyll-og-image/template/og-image.html")
template = Liquid::Template.parse(File.read(template_path))

test_cases = [
  {
    "title" => "Snapshots From Your Future",
    "date" => "April 21, 2026",
    "tags" => ["life", "meta", "philosophy", "blog-challenge-2026"],
    "file" => "test-short.png"
  },
  {
    "title" => "How I Compute (2026)",
    "date" => "April 21, 2026",
    "tags" => ["blog-challenge-2026", "computers"],
    "file" => "test-medium.png"
  },
  {
    "title" => "Building a CLI Tool That Doesn't Make You Want to Mass Delete node_modules",
    "date" => "March 15, 2026",
    "tags" => ["cli", "dx", "tooling"],
    "file" => "test-long.png"
  },
  {
    "title" => "/playlist/archive/master-list/".gsub("/", "/\u200B"),
    "date" => "",
    "tags" => [],
    "file" => "test-path.png"
  }
]

output_dir = File.join(__dir__, "test-output")
FileUtils.mkdir_p(output_dir)

browser = Ferrum::Browser.new(headless: true)
browser.resize(width: 1200, height: 630)

test_cases.each do |tc|
  html = template.render(
    "title" => tc["title"],
    "date" => tc["date"],
    "tags" => tc["tags"]
  )

  output_path = File.join(output_dir, tc["file"])
  puts "Generating #{tc['file']}..."

  browser.go_to("data:text/html;charset=utf-8,#{ERB::Util.url_encode(html)}")
  sleep 0.5 # let canvas and font sizing JS run
  browser.screenshot(path: output_path)

  puts "  Saved to #{output_path}"
end

browser.quit
puts "Done!"
