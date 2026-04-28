module JekyllOgImage
  class Config
    DEFAULTS = {
      "output_dir" => "assets/og",
      "layouts_dir" => "_og/layouts",
      "force" => false,
      "quiet" => false,
      "templates" => []
    }.freeze

    def initialize(jekyll_config)
      @config = DEFAULTS.merge(jekyll_config.fetch("og_image", {}))
    end

    def output_dir = @config["output_dir"]
    def layouts_dir = @config["layouts_dir"]
    def force? = @config["force"]
    def quiet? = @config["quiet"]
    def template_rules = @config["templates"]
  end
end
