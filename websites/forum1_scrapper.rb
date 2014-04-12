require_relative 'scrapper'
require_relative 'forum_helper'
require_relative '../hosts/host_factory'

class Forum1Scrapper < Scrapper
  include ForumHelper

  def credentials
    user = YAML.load_file('config/forums.yml')["forum1"]["username"]
    password = YAML.load_file('config/forums.yml')["forum1"]["password"]
    return user, password
  end

  def category_name(category_number)
    YAML.load_file('config/forums.yml')["forum1"]["category#{category_number}"]
  end

  def forum_topics(forum_page)
    doc = forum_page.parser
    doc.xpath('//tr[@class=""]//td[@class="title"]//a').reject {|i| i[:href].include?("page:")}.map { |i| i[:href]}
  end

  def host_urls_xpath
    '//div[@class="bodyContent"]//a'
  end

  def scrap_from_page(post_page, previous_scrapping_date)
    urls = host_urls(post_page)

    puts "All images scrapped on page : #{post_page.uri.to_s}" if urls.blank?

    urls.each do |host_url|
      if host_url.include?("http")
        page_image = page_image_at_host_url(host_url)
        download_image(page_image.url.to_s, page_image) if page_image.present?
      else
        base_url = YAML.load_file('config/forums.yml')["forum1"]["base_url"]
        download_image("#{base_url}#{host_url}", nil)
      end
    end

    go_to_next_page(post_page, previous_scrapping_date)
  end

  def next_link_text
    "»"
  end
end