require_relative 'scrapper'
require_relative 'website2_utils'

class Website2Scrapper < Scrapper
  include Website2Utils
  
  def do_scrap
    excluded_urls = YAML.load_file('private-conf/websites.yml')["website2"]["excluded_urls"]
    scrap_allowed_links(excluded_urls)
  end

  def allowed_links(excluded_urls)
    @current_page.links.map {|link| link if link.text.present? && !excluded_urls.any? {|s| link.href.include?(s)} && link.href.size>1}.compact
  end

  def scrap_allowed_links(excluded_urls)
    allowed_links(excluded_urls).each do |link|
      post_name = link.text
      post = Post.create(id, post_name)
      return if post.banished

      @post_id = post.id
      
      pp "Scrap : #{post.name}"
      page = link.click
      scrap_page(page)
    end
  end
end