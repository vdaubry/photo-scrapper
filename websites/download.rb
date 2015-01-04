require_relative '../models/facades/sqs'

module Download
  def download_image(url)
    if url.blank?
      puts "Tried to download empty url"
    end
    send_image_message(@website, @post, url)
  end

  def send_image_message(website, post, url)
    img_json_str = {:website_id => website, :post_id => post, :image_url => url, :scrapped_at => DateTime.now.to_s}.to_json
    send_except_for_test(img_json_str)
  end

  def send_except_for_test(json)
    Facades::SQS.new(ENV["IMAGE_QUEUE_NAME"]).send(json) unless ENV['TEST']
  end
end