module ForumHelper
  def authorize
    user, password = credentials
    pp "Sign in user : #{user}"
    sign_in(user, password)
  end

  def number_of_categories
    2
  end

  def do_scrap
    (1..number_of_categories).each do |category_number|
      scrap_posts_from_category(category_name(category_number), scrapping_date)
    end
  end

  def host_urls(post_page)
    doc = post_page.parser
    #all links that contains jpgs images
    links = doc.xpath(host_urls_xpath)

    hrefs = links
              .reject {|i| %w(mp4 hdv).any?{|term| i[:href].downcase.include?(term) } }
              .map { |i| i[:href] }
    already_downloaded_images = Image.find_by(id, {:hosting_urls => hrefs})
    hrefs = hrefs-already_downloaded_images.map(&:hosting_url) if already_downloaded_images
    hrefs.reject {|u| u.include?("profile")}
  end

  # def page_image_at_host_url(host_url)
  #   HostFactory.create_with_host_url(host_url).page_image rescue nil
  # end

  def scrap_posts_from_category(category_name, previous_scrapping_date)
    forum_page = category_forums(category_name)
    if forum_page
      links = forum_topics(forum_page)
      links.each do |link|
        begin
          post_page = forum_page.link_with(:href => link).click
          scrap_post_hosted_images(post_page, previous_scrapping_date)
        rescue Net::HTTP::Persistent::Error => e
          puts "error : #{e.to_s}"
        end
      end
    end
  end

  def scrap_post_hosted_images(post_page, previous_scrapping_date)
    pp "Scrap post for hosted images : #{post_page.title} - #{post_page.uri.to_s}"
    post = Post.create(id, post_page.title)
    return if post.banished
    @post_id = post.id
    
    scrap_from_page(post_page, previous_scrapping_date)
  end

  def direct_urls(post_page)
    doc = post_page.parser
    #all jpgs images that are not inside link
    doc.xpath(direct_urls_xpath).map{|i| i[:src]}
  end

  def scrap_from_page(post_page, previous_scrapping_date)
    hosted_urls = host_urls(post_page)
    puts "No hosted images to scrap on page : #{post_page.uri.to_s}" if hosted_urls.blank?

    hosted_urls.each do |host_url|      
      download_image(host_url)
    end

    forum_hosted_urls = direct_urls(post_page)
    puts "No direct images to scrap on page : #{post_page.uri.to_s}" if forum_hosted_urls.blank?

    forum_hosted_urls.each do |img_url|
      download_image(img_url)
    end

    go_to_next_page(post_page, previous_scrapping_date)
  end


  def next_link(post_page)
    post_page.link_with(:text => next_link_text)
  end

  def go_to_next_page(post_page, previous_scrapping_date)
    next_link_button = next_link(post_page)
    if next_link_button
      next_link_url = (post_page.uri.merge next_link_button.uri).to_s
      not_scrapped = Post.find_by(id, next_link_url).blank?

      if not_scrapped
        puts "Scrapping next page"
        begin 
          post_page = next_link_button.click
          Post.update(id, @post_id, next_link_url)
          scrap_from_page(post_page, previous_scrapping_date)
        rescue SocketError => e
          puts "error = #{e.to_s}"
        end
      else
        puts "Next page already scrapped : #{next_link_url}"
      end
    end
  end
end