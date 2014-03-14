module Download

  def download_image(url, page_image=nil)
    images = ImageApi.new.search(@website.id, {:source_url => url})
    if images.nil?
      puts "Image search failed"
      return
    end

    if images.first.nil?
      imageDownloader = ImageDownloader.new.build_info(@website.id, @post_id, url)
      pp "Save #{imageDownloader.key}"
      success = imageDownloader.download(page_image)
      @post_images_count += 1 if success
      sleep(1) unless ENV['TEST']
    else
      puts "Image search found a similar images : #{images.first.key}"
    end
  end
end