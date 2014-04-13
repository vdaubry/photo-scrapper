require_relative 'scrapper'
require_relative 'forum_helper'
require_relative '../hosts/host_factory'

class Forum4Scrapper < Scrapper
  include ForumHelper

  def credentials
    user = YAML.load_file('config/forums.yml')["forum4"]["username"]
    password = YAML.load_file('config/forums.yml')["forum4"]["password"]
    return user, password
  end

  def number_of_categories
    3
  end

  def sign_in(user, password)
    @current_page = @current_page.form_with(:name => nil) do |form|
      form.fields.first.value = user
      form.fields.second.value = password
    end.submit
    @current_page = @current_page.links.first.click
  end

  def category_name(category_number)
    YAML.load_file('config/forums.yml')["forum4"]["category#{category_number}"]
  end

  def forum_topics(forum_page)
    doc = forum_page.parser
    links = doc.xpath('//ol[@id="threads"]//li[contains(@class, "threadbit")]//a[contains(@id,"thread_title")]').map { |i| i[:href]}
  end

  def host_urls_xpath
    '//div[contains(@id, "post_message")]//a[child::img[contains(@src, "jpg") or contains(@src, "jpeg")]]'
  end

  def next_link_text
    "Next"
  end
end