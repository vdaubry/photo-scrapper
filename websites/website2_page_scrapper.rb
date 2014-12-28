require_relative 'scrapper'
require_relative 'website2_utils'

#A merger avec website2

class Website2PageScrapper < Scrapper
  include Website2Utils
  
  def do_scrap
    @specific_model = @params
    base_url = YAML.load_file('private-conf/websites.yml')["website2"]["base_url"]
    scrap_specific_page("#{base_url}/#{@specific_model}", @specific_model)
  end

  def scrap_specific_page(page_name, post_name)
    page = Mechanize.new.get(page_name)
    post = Post.create(id, post_name)
    @post_id = post.id

    scrap_page(page)
  end
end