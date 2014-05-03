module Download

  def download_image(url, page_image=nil)
    images = Image.find_by(id, {:source_url => url})
    if images.nil?
      puts "Image search failed"
      return
    end

    if images.first.nil?
      send_image_message(id, @post_id, url)
    else
      puts "Image search found a similar images : #{images.first.key}"
    end
  end

  def send_image_message(website_id, post_id, url)
    img_json_str = {:website_id => website_id, :post_id => post_id, :image_url => url}.to_json
    Facades::SQS.new.send(img_json) unless ENV['TEST']
  end
end