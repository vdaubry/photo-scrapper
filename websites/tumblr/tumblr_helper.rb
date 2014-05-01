module TumblrHelper

  def single_photo_xpath
    '//div[@class="media"]//a'
  end

  def direct_images_xpath
    '//div[@class="media"]//img[not(parent::a)]'
  end

  def direct_images_urls
    doc = @current_page.parser
    doc.xpath(direct_images_xpath).map {|img| img[:src]}
  end

  def single_photo_links
    doc = @current_page.parser

    direct_images = direct_images_urls
    links_to_image = []
    doc.xpath(single_photo_xpath).each do |link|
      if link[:href] .include?(url)
        links_to_image << link[:href] 
      else
        direct_images << link.xpath('//img').first[:src]
      end
    end
    links_to_image = links_to_image.map {|link| image_at_link(link)}.compact

    links_to_image+direct_images
  end

  def image_at_link(url)
    browser = Mechanize.new.get(url)
    doc = browser.parser
    doc.xpath('//img[@id="content-image"]').first["data-src"] rescue nil
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

  def do_scrap
    post = Post.create(id, post_name)
    @post_id = post.id

    image_links = single_photo_links+photoset_links

    image_links.each do |img_url|
      download_image(img_url)
    end

    go_to_next_page
  end

  def is_current_page_last_page
    @current_page.parser.xpath('//div[@class="post"]').blank?
  end

  def go_to_next_page
    page_number = 1
    if @current_page.uri.to_s.include?("page")
      page_number = URI.parse(@current_page.uri.to_s).path.split('/').last.to_i
    end

    next_link_url = "#{url}/page/#{page_number+1}"
    not_scrapped = Post.find_by(id, next_link_url).blank?

    if not_scrapped
      puts "Scrapping next page : #{next_link_url}"
      @current_page = Mechanize.new.get(next_link_url)

      unless is_current_page_last_page
        Post.update(id, @post_id, next_link_url)
        do_scrap
      end
    else
      puts "Next page already scrapped : #{next_link_url}"
    end
  end

end