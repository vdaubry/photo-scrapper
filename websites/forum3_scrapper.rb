require_relative 'scrapper'
require_relative 'forum_helper'
require_relative '../hosts/host_factory'

class Forum3Scrapper < Scrapper
  include ForumHelper

  def credentials
    user = YAML.load_file('config/forums.yml')["forum3"]["username"]
    password = YAML.load_file('config/forums.yml')["forum3"]["password"]
    return user, password
  end

  def sign_in(user, password)
    @current_page = @current_page.form_with(:name => nil) do |form|
      form.fields.first.value = user
      form.fields.second.value = password
    end.submit
  end

  def category_name(category_number)
    YAML.load_file('config/forums.yml')["forum3"]["category#{category_number}"]
  end

  def forum_topics(forum_page)
    doc = forum_page.parser
    links = doc.xpath('//td[contains(@class, "subject")]//a').select {|i| i[:href].include?("topic")}.map { |i| i[:href]}
  end

  def direct_urls_xpath
    '//div[@class="postarea"]//img[not(parent::a) and contains(@src, "jpg") or contains(@src, "jpeg")]'
  end

  def host_urls_xpath
    '//div[@class="postarea"]//a[child::img[contains(@src, "jpg") or contains(@src, "jpeg")]]'
  end

  def next_link(post_page)
    topic_id = post_page.canonical_uri.to_s.split("topic=").last
    next_topic_page="#{topic_id.split(".")[0]}.#{topic_id.split(".")[1].to_i+15}"
    post_page.link_with(:href => /#{next_topic_page}/)
  end
end