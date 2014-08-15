require_relative 'scrapper'
require_relative 'forum_helper'

class Forum1Scrapper < Scrapper
  include ForumHelper

  def credentials
    user = YAML.load_file('private-conf/forums.yml')["forum1"]["username"]
    password = YAML.load_file('private-conf/forums.yml')["forum1"]["password"]
    return user, password
  end

  def category_name(category_number)
    YAML.load_file('private-conf/forums.yml')["forum1"]["category#{category_number}"]
  end

  def forum_topics(forum_page)
    doc = forum_page.parser
    multiple_page_topics = doc.xpath('//tr[@class=""]//td[@class="title"]//div[@class="smallPaging"]//a[last()]').map { |i| i[:href]}
    single_page_topic = doc.xpath('//tr[@class=""]//td[@class="title" and not(div[@class="smallPaging"]/a)]//a').map { |i| i[:href]}
    return multiple_page_topics+single_page_topic
  end

  def host_urls_xpath
    '//div[@class="bodyContent"]//a[not(contains(@href, "postimage"))]'
  end

  def direct_urls_xpath
    '//div[@class="bodyContent"]//img[parent::a[contains(@href, "postimage")]]'
  end

  def scrap_from_page(post_page, previous_scrapping_date)
    urls = host_urls(post_page)
    hotlink_urls = direct_urls(post_page)
    puts "All images scrapped on page : #{post_page.uri.to_s}" if urls.blank? && hotlink_urls.blank?

    urls.each do |host_url|
      if host_url.include?("http")
        download_image(host_url)
      else
        base_url = YAML.load_file('private-conf/forums.yml')["forum1"]["base_url"]
        download_image("#{base_url}#{host_url}")
      end
    end

    hotlink_urls.each do |hotlink_url|
      download_image(hotlink_url)
    end

    go_to_next_page(post_page, previous_scrapping_date)
  end

  def next_link_text
    "«"
  end

end