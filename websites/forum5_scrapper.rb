require_relative 'scrapper'
require_relative 'forum_helper'
require_relative '../hosts/host_factory'

class Forum5Scrapper < Scrapper
  include ForumHelper

  def credentials
    nil
  end

  def number_of_categories
    5
  end

  def sign_in(user, password)
  end

  def category_name(category_number)
    YAML.load_file('config/forums.yml')["forum5"]["category#{category_number}"]
  end

  def forum_topics(forum_page)
    doc = forum_page.parser
    links = doc.xpath('//td[@class="row1"]//a[@class="topictitle"]').map { |i| i[:href]}
  end

  def host_urls_xpath
    '//span[@class="postbody"]//a[child::img[contains(@src, "jpg") or contains(@src, "jpeg")]]'
  end

  def direct_urls_xpath
    '___'
  end

  def next_link_text
    "Next"
  end
end