class ScrapperFactory

  def initialize(website_name)
    @website_name = website_name
  end

  def scrapper
    yml = ['forums.yml','websites.yml', 'tumblr.yml'].select {|yml| YAML.load_file("private-conf/#{yml}").include?(@website_name)}.first
    class_name = YAML.load_file("private-conf/#{yml}")[@website_name]["class_name"]
    if class_name
      scrapper = Object.const_get(class_name)
      scrapper.new(YAML.load_file("private-conf/#{yml}")[@website_name]["url"])
    end
  end
end