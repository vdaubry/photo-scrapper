require_relative 'scrapper'

class Website3Scrapper < Scrapper
  
  def home_page
    agent = Mechanize.new
    agent.user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:31.0) Gecko/20100101 Firefox/31.0"
    @current_page = agent.get(url+"?page=8")
  end
  
  def links
    links = @current_page.links_with(:href => /posts/).uniq {|link| link.href}
  end
  
  def do_scrap
    @page_number ||= 8
    puts "scrapping page : #{@page_number}"
    
    subpage_links = links
    puts "found #{subpage_links.count} subpage to scrap"
    
    subpage_links.each do |link|
      page = link.click
      scrap_page(page)
    end
    
    @page_number+=1
    go_to_next_page(@page_number)
  end
  
  def images_urls(page)
    image_hash = page.parser.xpath("//input[@id='ol_value']/@value").first.value
    images_ids = JSON.parse(image_hash).map {|h| h["anum"]}
    images_ids.map {|id| "#{url}/photos/#{id}.jpg"}
  end
  
  def scrap_page(page)
    puts "scrapping page #{@page_number}: #{page.title}"
    post = Post.create(id, page.title)
    @post_id = post.id
    
    images_to_download = images_urls(page)
    puts "Found #{images_to_download.count} images"
    
    images_to_download.each do |url|
      download_image(url)
    end
  end
  
  def next_page_url(page_number)
    next_page_param = @current_page.link_with(:href => "/?page=#{page_number}").uri.to_s
    "#{url}#{next_page_param}"
  end
  
  def go_to_next_page(page)
    url = next_page_url(page)
    if url
      puts "go to next page : #{url}"
      begin
        @current_page = Mechanize.new.get(url)
      rescue Mechanize::ResponseCodeError => e
        puts "error = #{e.to_s}"
      end
      do_scrap
    end
  end

end