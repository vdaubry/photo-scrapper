require_relative 'scrapper'

class Website2Scrapper < Scrapper
  attr_accessor :specific_model
  
  def do_scrap
    if @specific_model
      base_url = YAML.load_file('private-conf/websites.yml')["website2"]["base_url"]
      scrap_specific_page("#{base_url}/#{@specific_model}", @specific_model)
    else
      excluded_urls = YAML.load_file('private-conf/websites.yml')["website2"]["excluded_urls"]
      scrap_allowed_links(excluded_urls)
    end
    
  end

  def allowed_links(excluded_urls)
    @current_page.links.map {|link| link if link.text.present? && !excluded_urls.any? {|s| link.href.include?(s)} && link.href.size>1}.compact
  end

  def scrap_allowed_links(excluded_urls)
    allowed_links(excluded_urls).each do |link|
      post_name = link.text
      post = Post.create(id, post_name)
      return if post.banished

      @post_id = post.id
      
      pp "Scrap : #{post.name}"
      page = link.click
      scrap_page(page)
    end
  end

  def scrap_specific_page(page_name, post_name)
    page = Mechanize.new.get(page_name)
    post = Post.create(id, post_name)
    @post_id = post.id

    scrap_page(page)
  end

  def latest_pic_date(image_id)
    browser = Mechanize.new
    post_url = YAML.load_file('private-conf/websites.yml')["website2"]["post_url"]
    response_doc = browser.post(post_url, {"req" => "pexpand", "pid" => image_id}).parser
    response_doc.xpath("//body").children[0].text.scan(/added on: (.*)/).last.first
  end

  def scrap_page(page)
    doc = page.parser
    model = doc.css('script')[2].children.text.scan(/messanger\.cfname = '(.*?)'/).last.first
    host = YAML.load_file('private-conf/websites.yml')["website2"]["images_host"]
    keyword = YAML.load_file('private-conf/websites.yml')["website2"]["keyword"]
    pids = doc.css('script')[4].children.text.scan(/pid\":(.*?),/)
    most_recent_pic = pids.map {|pid| pid.first.to_i}.sort.last
    added_on = latest_pic_date(most_recent_pic)
    most_recent_image = Image.find_by(id, {:source_url => "#{host}/#{model}-#{keyword}-#{most_recent_pic}.jpg"})
    
    if most_recent_image.present?
      puts "No new images"
    else
      images_urls = pids.map {|pid| "#{host}/#{model}-#{keyword}-#{pid.first}.jpg"} 

      images_urls.each do |url|
        download_image(url)
      end
    end
  end
end