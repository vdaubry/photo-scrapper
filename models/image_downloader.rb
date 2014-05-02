require 'open-uri'
require 'open_uri_redirections'
require 'fastimage'
require 'mini_magick'
require 'active_support/time'
require 'benchmark'
require 'progressbar'
require 'image_optim'
require_relative 'facades/ftp'
require_relative 'image'

class ImageDownloader
  TO_SORT_STATUS="TO_SORT_STATUS"

  attr_accessor :source_url, :hosting_url, :key, :status, :image_hash, :width, :height, :file_size, :website_id, :post_id

  def initialize(key=nil)
    @key = key
  end

  def key_from_url(source_url)
    image_path = File.basename(URI.parse(source_url).path)
    DateTime.now.to_i.to_s + "_" + image_path.gsub('-', '_').gsub(/[^0-9A-Za-z_\.]/, '')
  end

  def build_info(website_id, post_id, source_url, hosting_url=nil)
    @website_id = website_id
    @post_id = post_id
    @source_url = source_url
    @hosting_url = hosting_url
    begin
      @key = key_from_url(source_url)
    rescue URI::InvalidURIError => e
      puts e.to_s
    end
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

  def compress_image
    File.open(image_save_path) {|f| puts "size before = #{f.size}"}
    image_optim = ImageOptim.new(:pngout => false, :jpegoptim => {:max_quality => 85})
    image_optim.optimize_image!(image_save_path)
    File.open(image_save_path) {|f| puts "size after = #{f.size}"}
  end

  def get_remote_image(page_image)
    if page_image
      puts "Downloading with mechanize #{page_image.url.to_s}"
      puts Benchmark.measure { 
        page_image.fetch.save image_save_path #To protect from hotlinking we reuse the same session
      }
    else
      puts "Downloading with open-uri : #{source_url}"
      puts Benchmark.measure { 
        open(image_save_path, 'wb') do |file|
          file << open(source_url, :allow_redirections => :all).read
        end
      }
    end
  end

  def download(page_image=nil)
    result = false
    rescue_errors do
      get_remote_image(page_image)
      compress_image
      set_image_info
      generate_thumb
      result = Image.create(website_id, post_id, source_url, hosting_url, key, status, image_hash, width, height, file_size).present?            
      Ftp.new.upload_file(self) if result
    end
    
    result
  end

  def rescue_errors
    begin
      yield
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
    rescue MiniMagick::Invalid => e
      puts e.to_s
    rescue Errno::ENOMEM => e
      puts e.to_s
    ensure
      clean_images
    end
  end
end
