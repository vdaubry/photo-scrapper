require_relative 'scrapper'

class Website1Scrapper < Scrapper

  def home_page
    agent = Mechanize.new
    agent.set_proxy("92.222.1.55", 3128, "photo-visualizer", ENV['SQUID_PASSWORD'])
    @current_page = agent.get(url)
  end

  def scrapping_date
    1.month.ago.beginning_of_month
  end

  def authorize
    user = YAML.load_file('private-conf/websites.yml')["website1"]["username"]
    password = YAML.load_file('private-conf/websites.yml')["website1"]["password"]
    pp "Sign in user : #{user}"
    sign_in(user, password)
  end

  def do_scrap
    top_link = YAML.load_file('private-conf/websites.yml')["website1"]["top_link"]
    top_page(top_link)

    images_saved = 0
    (1..12).each do |category_number|
      category_name = YAML.load_file('private-conf/websites.yml')["website1"]["category#{category_number}"]
      category_page = category(category_name, scrapping_date)
      scrap_category(category_page, scrapping_date)
    end
  end

  def top_page(top_link)
    @current_page = @current_page.link_with(:text => top_link).click
  end

  def category(category_name, month)
    pp "Go to category : #{category_name} - #{month.strftime("%Y/%B")}"
    @current_post_name = "#{category_name}_#{month.strftime("%Y_%B")}"

    page = @current_page.link_with(:text => category_name).click
    page = page.link_with(:text => month.strftime("%Y")).click
    page.link_with(:text => month.strftime("%B")).click
  end

  #Very similar to ForumHelper:scrap_post_hosted_images => except we don't use the current page title as post name, but the current category being scrapped. To refactor ?
  def scrap_category(category_page, month)
    puts "creating post  = #{@current_post_name}"

    post = Post.create(id, @current_post_name)
    @post_id = post.id
    
    link_reg_exp = YAML.load_file('private-conf/websites.yml')["website1"]["link_reg_exp"]
    links = category_page.links_with(:href => %r{#{link_reg_exp}})#[0..1]
    pp "Found #{links.count} links" 
    links.each do |link|
      parse_image(link)
    end
  end

  def parse_image(link)
    page = link.click
    page_image = page.image_with(:src => %r{/norm/})

    if page_image
      image_url = page_image.url.to_s
      download_image(image_url)
    end
  end

end