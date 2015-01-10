require "byebug"

module Website2Utils
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
    keyword = YAML.load_file('private-conf/websites.yml')["website2"]["image_keyword"]
    pids = doc.css('script').select {|s| s.children.text.scan(/pid\":(.*?),/).present?}.first.children.text.scan(/pid\":(.*?),/)
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