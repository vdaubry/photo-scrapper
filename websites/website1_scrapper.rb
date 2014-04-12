require_relative 'scrapper'

class Website1Scrapper < Scrapper

  def scrapping_date
    1.month.ago.beginning_of_month
  end

  def authorize
    user = YAML.load_file('config/websites.yml')["website1"]["username"]
    password = YAML.load_file('config/websites.yml')["website1"]["password"]
    top_link = YAML.load_file('config/websites.yml')["website1"]["top_link"]
    pp "Sign in user : #{user}"
    sign_in(user, password)
  end

  def do_scrap
    top_link = YAML.load_file('config/websites.yml')["website1"]["top_link"]
    top_page(top_link)

    images_saved = 0
    (1..12).each do |category_number|
      category_name = YAML.load_file('config/websites.yml')["website1"]["category#{category_number}"]
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

  def scrap_category(category_page, month)
    puts "creating post  = #{@current_post_name}"

    post = Post.create(id, @current_post_name)
    @post_id = post.id
    @post_images_count = 0
    
    link_reg_exp = YAML.load_file('config/websites.yml')["website1"]["link_reg_exp"]
    links = category_page.links_with(:href => %r{#{link_reg_exp}})#[0..1]
    pp "Found #{links.count} links" 
    links.each do |link|
      parse_image(link)
    end

    Post.destroy(id, @post_id) if @post_images_count==0
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