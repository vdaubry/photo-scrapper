require_relative 'base_website'
require_relative 'navigation'
require_relative 'download'
require_relative 'scrapping_date'
require_relative '../hosts/host_factory'

class Forum2 < BaseWebsite
  include Navigation
  include Download
  include ScrappingDate

  def sign_in(user, password)
    sign_in_page = @current_page.links.find { |l| l.text == 'Log-in' }.click
    @current_page = sign_in_page.form_with(:name => nil) do |form|
      form.fields.first.value = user
      form.fields.second.value = password
    end.submit
  end

  def forum_topics(forum_page)
    doc = forum_page.parser
    doc.xpath('//tr[contains(@class, "row") and not(contains(@class, "sticky"))]//td[contains(@class, "firstcol") or contains(@class, "topic-titles")]//a').map {|i| i[:href]}
  end

  def host_urls(post_page)
    doc = post_page.parser
    links = doc.xpath('//div[contains(@class, "post-body")]//a')

    hrefs = links.map { |i| i[:href] }
    already_downloaded_images = ImageApi.new.search(@website.id, {:hosting_urls => hrefs})
    hrefs = hrefs-already_downloaded_images.map(&:hosting_url) if already_downloaded_images
    hrefs.reject {|u| u.include?("profile")}
  end

  def page_image_at_host_url(host_url)
    puts "#{host_url}"
    HostFactory.create_with_host_url(host_url).page_image
  end
  
  def scrap_posts_from_category(category_name, previous_scrapping_date)
    forum_page = category_forums(category_name)
    links = forum_topics(forum_page)
    links.each do |link|
      post_page = forum_page.link_with(:href => link).click
      scrap_post_hosted_images(post_page, previous_scrapping_date)
    end
  end

  def scrap_post_hosted_images(post_page, previous_scrapping_date)
    pp "Scrap post for hosted images : #{post_page.title} - #{post_page.uri.to_s}"
    post = PostApi.new.create(@website.id, post_page.title)
    @post_id = post.id
    @post_images_count = 0

    scrap_from_page(post_page, previous_scrapping_date)

    PostApi.new.destroy(@website.id, @post_id) if @post_images_count==0
  end

  def scrap_from_page(post_page, previous_scrapping_date)
    urls = host_urls(post_page)

    puts "All images scrapped on page : #{post_page.uri.to_s}" if urls.blank?

    urls.each do |host_url|
      if host_url.include?("http")
        page_image = page_image_at_host_url(host_url)
        download_image(page_image.url.to_s, page_image) if page_image.present?
      else
        base_url = YAML.load_file('config/forums.yml')["forum1"]["base_url"]
        download_image("#{base_url}#{host_url}", nil)
      end
    end

    go_to_next_page(post_page, previous_scrapping_date)
  end

  def go_to_next_page(post_page, previous_scrapping_date)
    next_link = post_page.link_with(:text => "Next»")
    pp "next_link = #{next_link}"
    if next_link
      next_link_url = (post_page.uri.merge next_link.uri).to_s
      not_scrapped = PostApi.new.search(@website.id, next_link_url).blank?
      if not_scrapped
        puts "Scrapping next page"
        PostApi.new.update(@website.id, @post_id, next_link_url)
        
        post_page = next_link.click
        scrap_from_page(post_page, previous_scrapping_date)
      else
        puts "Next page already scrapped : #{post_page.uri.to_s}"
      end
    end 
  end
end