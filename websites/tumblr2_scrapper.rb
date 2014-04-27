require_relative 'scrapper'

class Tumblr2Scrapper < Scrapper

  def single_photo_links
    doc = @current_page.parser
    links = doc.xpath('//div[@class="photo-wrapper-inner"]//a').map {|img| img[:href]}
    links.map {|link| image_at_link(link)}
  end

  def image_at_link(url)
    browser = Mechanize.new.get(url)
    doc = browser.parser
    doc.xpath('//img[@id="content-image"]').first["data-src"]
  end

  def do_scrap
    post_name = YAML.load_file('private-conf/tumblr.yml')["tumblr2"]["post_name"]
    post = Post.create(id, post_name)
    @post_id = post.id

    image_links = single_photo_links

    image_links.each do |img_url|
      download_image(img_url)
    end

    go_to_next_page
  end

  def is_current_page_last_page
    @current_page.parser.xpath('//div[@class="post-wrapper clearfix"]').blank?
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