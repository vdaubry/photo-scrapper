require 'open-uri'
require 'fastimage'
require 'mini_magick'
require 'active_support/time'
require_relative 'facades/ftp'

class ImageDownloader
  TO_SORT_STATUS="TO_SORT_STATUS"

  attr_accessor :source_url, :hosting_url, :key, :status, :image_hash, :width, :height, :file_size

  def initialize(key=nil)
    @key = key
  end

  def build_info(source_url, hosting_url=nil)
    @source_url = source_url
    @hosting_url = hosting_url
    @key = (DateTime.now.to_i.to_s + "_" + File.basename(URI.parse(source_url).path)).gsub('-', '_').gsub(/[^0-9A-Za-z_\.]/, '')
    @status = ImageDownloader::TO_SORT_STATUS
    self
  end

  def self.image_path
    "tmp/images"
  end

  def self.thumbnail_path
    "tmp/images/thumbnails/300"
  end

  def image_save_path
    "#{ImageDownloader.image_path}/#{@key}"
  end

  def generate_thumb
    image = MiniMagick::Image.open(image_save_path) 
    image.resize "300x300"
    image.write  "#{ImageDownloader.thumbnail_path}/#{@key}"
  end

  def set_image_info
    image_file = File.read(image_save_path)
    self.image_hash = Digest::MD5.hexdigest(image_file)
    self.width = FastImage.size(image_save_path)[0]
    self.height = FastImage.size(image_save_path)[1]
    self.file_size = image_file.size
  end

  def image_invalid?
    too_small = (@width < 300 || @height < 300)
    puts "Too small" if too_small
    #already_downloaded = Image.where(:image_hash => image_hash).count > 0
    #Rails.logger.warn "already_downloaded" if already_downloaded
    #(too_small || already_downloaded)
    too_small
  end

  def download(page_image=nil)
    begin
      if page_image
        page_image.fetch.save image_save_path #To protect from hotlinking we reuse the same session
      else
        open(image_save_path, 'wb') do |file|
          file << open(source_url, :allow_redirections => :all).read
        end
      end

      generate_thumb
      set_image_info
      Ftp.new.upload_file(self)

      #TODO : call API

    rescue Timeout::Error, Errno::ENOENT => e
      puts e.to_s
    rescue OpenURI::HTTPError => e
      puts "40x error at url : #{source_url}, deleting image"+e.to_s
    end
  end

end
