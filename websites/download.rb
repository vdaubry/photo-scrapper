require_relative '../models/facades/sqs'

module Download
  def download_image(url)
    if url.blank?
      puts "Tried to download empty url"
      return true
    end
    
    images = Image.find_by(id, {:source_url => url})
    if images.nil?
      puts "Image search failed"
      return true
    end

    if images.first.nil?
      send_image_message(id, @post_id, url)
      return true
    else
      puts "Image search found a similar image : #{images.first.key}"
      return false
    end
  end

  def send_image_message(website_id, post_id, url)
    img_json_str = {:website_id => website_id, :post_id => post_id, :image_url => url, :scrapped_at => DateTime.now.to_s}.to_json
    send_except_for_test(img_json_str)
  end

  def send_except_for_test(json)
    Facades::SQS.new(ENV["IMAGE_QUEUE_NAME"]).send(json) unless ENV['TEST']
  end
end