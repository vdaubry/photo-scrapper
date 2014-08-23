require_relative '../models/facades/sqs'

module Download
  def download_image(url)
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
    img_json_str = {:website_id => website_id, :post_id => post_id, :image_url => url, :scrapped_at => DateTime.now.to_s}.to_json
    send_except_for_test(img_json_str)
  end

  def send_except_for_test(json)
    Facades::SQS.new(ENV["IMAGE_QUEUE_NAME"]).send(img_json_str) unless ENV['TEST']
  end
end