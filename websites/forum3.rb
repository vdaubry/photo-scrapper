require_relative 'base_website'
require_relative 'navigation'
require_relative 'download'
require_relative 'scrapping_date'
require_relative '../hosts/host_factory'

class Forum3 < BaseWebsite
  include Navigation
  include Download
  include ScrappingDate

  def sign_in(user, password)
    @current_page = @current_page.form_with(:name => nil) do |form|
      form.fields.first.value = user
      form.fields.second.value = password
    end.submit
  end

  def forum_topics(forum_page)
    doc = forum_page.parser
    links = doc.xpath('//td[contains(@class, "subject")]//a').select {|i| i[:href].include?("topic")}.map { |i| i[:href]}
  end

  def host_urls(post_page)
    doc = post_page.parser
    #all links that contains jpgs images
    links = doc.xpath('//div[@class="postarea"]//a[child::img[contains(@src, "jpg") or contains(@src, "jpeg")]]')

    hrefs = links
              .reject {|i| %w(mp4 hdv).any?{|term| i[:href].downcase.include?(term) } }
              .map { |i| i[:href] }
    already_downloaded_images = ImageApi.new.search(@website.id, {:hosting_urls => hrefs})
    hrefs = hrefs-already_downloaded_images.map(&:hosting_url) if already_downloaded_images
    hrefs.reject {|u| u.include?("profile")}
  end

  def direct_urls(post_page)
    doc = post_page.parser
    #all jpgs images that are not inside link
    doc.xpath('//div[@class="postarea"]//img[not(parent::a) and contains(@src, "jpg") or contains(@src, "jpeg")]').map{|i| i[:src]}
    
  end

  def page_image_at_host_url(host_url)
    HostFactory.create_with_host_url(host_url).page_image rescue nil
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
    hosted_urls = host_urls(post_page)
    puts "No hosted images to scrap on page : #{post_page.uri.to_s}" if hosted_urls.blank?

    hosted_urls.each do |host_url|
      page_image = page_image_at_host_url(host_url)
      download_image(page_image.url.to_s, page_image) if page_image.present?
    end

    forum_hosted_urls = direct_urls(post_page)
    puts "No direct images to scrap on page : #{post_page.uri.to_s}" if forum_hosted_urls.blank?

    forum_hosted_urls.each do |img_url|
      download_image(img_url)
    end

    go_to_next_page(post_page, previous_scrapping_date)
  end

  def go_to_next_page(post_page, previous_scrapping_date)
    topic_id = post_page.canonical_uri.to_s.split("topic=").last
    next_topic_page="#{topic_id.split(".")[0]}.#{topic_id.split(".")[1].to_i+15}"
    next_link = post_page.link_with(:href => /#{next_topic_page}/)
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