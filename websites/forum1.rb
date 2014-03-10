require_relative 'base_website'
require_relative 'navigation'
require_relative 'download'
require_relative 'scrapping'

class Forum1 < BaseWebsite
  include Navigation
  include Download
  include Scrapping

  def forum_topics(forum_page)
    doc = forum_page.parser
    doc.xpath('//tr[@class=""]//td[@class="title"]//a').reject {|i| i[:href].include?("page:")}.map { |i| i[:href]}
  end

  def host_urls(post_page)
    doc = post_page.parser
    links = doc.xpath('//div[@class="bodyContent"]//a')
    base_url = YAML.load_file('config/forums.yml')["forum1"]["base_url"]
    host_urls = links.map { |i| i[:href] }.reject {|u| u.include?("profile") || Image.where(:hosting_url => u).first.present?}
  end
  
  def scrap_posts_from_category(category_name, previous_scrapping_date)
    forum_page = category_forums(category_name)
    links = forum_topics(forum_page)
    links.each do |link|
      post_page = forum_page.link_with(:href => link).click
      scrap_post_hosted_images(post_page, previous_scrapping_date)
    end
  end

  def scrap_post_hosted_images(post_page, previous_scrapping_date)
    pp "Scrap post for hosted images : #{post_page.title} - #{post_page.uri.to_s}"
    post = PostApi.new.create(@website.id, post_page.title)
    @post_id = post.id
    @post_images_count = 0

    scrap_from_first_page(post_page, previous_scrapping_date)

    PostApi.new.destroy(@website.id, @post_id) if @post_images_count==0
  end

  def scrap_from_first_page(post_page, previous_scrapping_date)
    urls = host_urls(post_page)
    urls.each do |host_url|

    end
  end
end