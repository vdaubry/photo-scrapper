require 'rubygems'
require 'bundler/setup'
require 'mechanize'

class Website1

  attr_reader :url

  def initialize(url)
    @url = url
  end

  def home_page
    @current_page = Mechanize.new.get(url)
  end

  def previous_month
    previous_month = website.last_scrapping_date.nil? ? 1.month.ago.beginning_of_month : (website.last_scrapping_date - 1.month).beginning_of_month
  end

  def sign_in(user, password, top_link)
    sign_in_page = @current_page.links.find { |l| l.text == 'Log-in' }.click
    @current_page = sign_in_page.form_with(:name => nil) do |form|
      form.fields.second.value = user
      form.fields.third.value = password
    end.submit
  end

  def top_page
    top_page = @current_page.link_with(:text => top_link).click
  end
end