require_relative 'scrapper'

class Website2Scrapper < Scrapper
  def do_scrap
    if @specific_model
      base_url = YAML.load_file('private-conf/websites.yml')["website2"]["base_url"]
      scrap_specific_page("#{base_url}/#{@specific_model}", @specific_model)
    else
      excluded_urls = YAML.load_file('private-conf/websites.yml')["website2"]["excluded_urls"]
      scrap_allowed_links(excluded_urls, scrapping_date)
    end
    
  end

  def allowed_links(excluded_urls)
    @current_page.links.map {|link| link if link.text.present? && !excluded_urls.any? {|s| link.href.include?(s)} && link.href.size>1}.compact
  end

  def scrap_allowed_links(excluded_urls, previous_scrapping_date)
    allowed_links(excluded_urls).each do |link|
      post_name = link.text
      post = Post.create(id, post_name)
      return if post.banished

      @post_id = post.id
      
      pp "Scrap : #{post.name} since #{previous_scrapping_date}"
      page = link.click
      scrap_page(page, previous_scrapping_date)
    end
  end

  def scrap_specific_page(page_name, post_name)
    page = Mechanize.new.get(page_name)
    post = Post.create(id, post_name)
    @post_id = post.id

    button = next_page_button(page)
    @has_next_page = button.present?
    @model_id = model_id(page)
    scrap_page(page, 10.year.ago)
  end

  def latest_pic_date(image_id)
    browser = Mechanize.new
    post_url = YAML.load_file('private-conf/websites.yml')["website2"]["post_url"]
    response_doc = browser.post(post_url, {"req" => "pexpand", "pid" => image_id}).parser
    response_doc.xpath("//body").children[0].text.scan(/added on: (.*)/).last.first
  end

  def scrap_page(page, previous_scrapping_date)
    doc = page.parser
    model = doc.css('script')[2].children.text.scan(/messanger\.cfname = '(.*?)'/).last.first
    pids = doc.css('script')[4].children.text.scan(/pid\":(.*?),/)
    most_recent_pic = pids.map {|pid| pid.first.to_i}.sort.last
    added_on = latest_pic_date(most_recent_pic)
    
    if Date.parse(added_on) >= previous_scrapping_date
      host = YAML.load_file('private-conf/websites.yml')["website2"]["images_host"]
      keyword = YAML.load_file('private-conf/websites.yml')["website2"]["keyword"]

      images_urls = pids.map {|pid| "#{host}/#{model}-#{keyword}-#{pid.first}.jpg"} 

      images_urls.each do |url|
        download_image(url)
      end

    else
      puts "No new images since #{previous_scrapping_date}"
    end
  end
end