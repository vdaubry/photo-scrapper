require 'open-uri'
require 'open_uri_redirections'
require 'fastimage'
require 'mini_magick'
require 'active_support/time'
require 'benchmark'
require 'progressbar'
require_relative 'facades/ftp'
require_relative 'image_api'

class ImageDownloader
  TO_SORT_STATUS="TO_SORT_STATUS"

  attr_accessor :source_url, :hosting_url, :key, :status, :image_hash, :width, :height, :file_size, :website_id, :post_id

  def initialize(key=nil)
    @key = key
  end

  def build_info(website_id, post_id, source_url, hosting_url=nil)
    @website_id = website_id
    @post_id = post_id
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

  def thumbnail_save_path
    "#{ImageDownloader.thumbnail_path}/#{@key}"
  end  

  def generate_thumb
    image = MiniMagick::Image.open(image_save_path) 
    image.resize "300x300"
    image.write thumbnail_save_path
  end

  def set_image_info
    image_file = File.read(image_save_path)
    self.image_hash = Digest::MD5.hexdigest(image_file)
    image_size = FastImage.size(image_save_path)
    if image_size
      self.width = image_size[0]
      self.height = image_size[1]
    end
    self.file_size = image_file.size
  end

  def clean_images
    File.delete(image_save_path) if File.exist?(image_save_path)
    File.delete(thumbnail_save_path) if File.exist?(thumbnail_save_path)
  end

  def download(page_image=nil)
    result = false
    pbar = nil
    begin
      if page_image
        puts "Downloading with mechanize"
        puts Benchmark.measure { 
          page_image.fetch.save image_save_path #To protect from hotlinking we reuse the same session
        }
      else
        puts "Downloading with open-uri"
        puts Benchmark.measure { 
          open(image_save_path, 'wb') do |file|
            file << open(source_url, 
                      :allow_redirections => :all,
                      :content_length_proc => lambda { |t|
                      if t && t > 0
                        pbar = ProgressBar.new("...", t)
                        pbar.file_transfer_mode
                      end
                      },
                      :progress_proc => lambda {|s|
                        pbar.set s if pbar
                      }).read
          end
        }
      end
      
      set_image_info
      generate_thumb
      result = ImageApi.new.post(website_id, post_id, source_url, hosting_url, key, status, image_hash, width, height, file_size).present?            
      Ftp.new.upload_file(self) if result
        
    rescue Timeout::Error, Errno::ENOENT => e
      puts e.to_s
    rescue OpenURI::HTTPError => e
      puts "40x error at url : #{source_url}"+e.to_s
    rescue Errno::ECONNRESET => e
      puts e.to_s
    rescue EOFError => e
      puts e.to_s
    rescue SocketError => e
      puts e.to_s
    rescue Mechanize::ResponseCodeError => e
      puts e.to_s
    rescue RuntimeError => e
      puts "progressbar error :"+e.to_s
    rescue Zlib::BufError => e
      puts e.to_s
    rescue Net::HTTP::Persistent::Error => e
      puts e.to_s
    rescue Errno::ECONNREFUSED => e
      puts e.to_s
    ensure
      clean_images
    end
    result
  end

end
