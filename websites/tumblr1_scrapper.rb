require_relative 'scrapper'

class Tumblr1Scrapper < Scrapper

  def image_links
    doc = @current_page.parser
    single_photo_links = doc.xpath('//div[@class="photo_holder"]//a').map {|img| img[:href]}

    photoset_links = []
    @current_page.iframes_with(:src => /post/).each do |iframe|
      photoset = iframe.click
      doc = photoset.parser
      photoset_links += doc.xpath('//a').map {|img| img[:href]}
    end

    single_photo_links+photoset_links
  end

  def do_scrap
    image_links.each do |img_url|
      download_image(img_url)
    end
  end

end