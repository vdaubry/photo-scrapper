require_relative 'scrapper'

class Tumblr1Scrapper < Scrapper

  def post_name
    doc = @current_page.parser
    doc.xpath('//div[@class="date_and_notes"]//a')
  end

  def photoset_links
    links = []
    @current_page.iframes_with(:src => /post/).each do |iframe|
      photoset = iframe.click
      doc = photoset.parser
      links += doc.xpath('//a').map {|img| img[:href]}
    end
    links
  end

  def single_photo_links
    doc = @current_page.parser
    links = doc.xpath('//div[@class="photo_holder"]//a').map {|img| img[:href]}
    links.map {|link| image_at_link(link)}
  end

  def image_at_link(url)
    browser = Mechanize.new.get(url)
    doc = browser.parser
    doc.xpath('//img[@id="content-image"]').first["data-src"]
  end

  def do_scrap
    post_name = YAML.load_file('private-conf/tumblr.yml')["tumblr1"]["post_name"]
    post = Post.create(id, post_name)
    @post_id = post.id

    image_links = single_photo_links+photoset_links

    image_links.each do |img_url|
      download_image(img_url)
    end
  end
end