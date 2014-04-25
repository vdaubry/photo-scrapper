module Download

  def download_image(url, page_image=nil)
    images = Image.find_by(id, {:source_url => url})
    if images.nil?
      puts "Image search failed"
      return
    end

    if images.first.nil?
      imageDownloader = ImageDownloader.new.build_info(id, @post_id, url)
      if imageDownloader.key
        pp "Save #{imageDownloader.key}"
        success = imageDownloader.download(page_image)
        sleep(1) unless ENV['TEST']
      end
    else
      puts "Image search found a similar images : #{images.first.key}"
    end
  end
end