require_relative 'scrapper'
require_relative 'forum_helper'
require_relative '../hosts/host_factory'

class Forum2Scrapper < Scrapper
  include ForumHelper

  def credentials
    user = YAML.load_file('config/forums.yml')["forum2"]["username"]
    password = YAML.load_file('config/forums.yml')["forum2"]["password"]
    return user, password
  end

  def category_name(category_number)
    YAML.load_file('config/forums.yml')["forum2"]["category#{category_number}"]
  end

  def sign_in(user, password)
    @current_page = @current_page.form_with(:name => nil) do |form|
      form.fields.second.value = user
      form.fields.third.value = password
    end.submit
  end

  def forum_topics(forum_page)
    doc = forum_page.parser
    doc.xpath('//tr[contains(@class, "row") and not(contains(@class, "sticky"))]//td[contains(@class, "firstcol") or contains(@class, "topic-titles")]//a').select {|i| i[:href].include?("topic")}.map{|i| i[:href]}
  end

  def direct_urls_xpath
    '//div[contains(@class, "post-body")]//img[not(parent::a) and contains(@src, "jpg") or contains(@src, "jpeg")]'
  end

  def host_urls_xpath
    '//div[contains(@class, "post-body")]//a[child::img[contains(@src, "jpg") or contains(@src, "jpeg")]]'
  end

  def next_link_text
    "Next»"
  end
end