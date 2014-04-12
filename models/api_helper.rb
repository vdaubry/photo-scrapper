require 'retriable'

module ApiHelper
  def retry_call
    exponential_backoff = ENV['TEST'] ? 0.1 : 4

    begin
      Retriable.retriable :times => 3, :interval => lambda {|attempts| attempts ** exponential_backoff} do
        yield
      end
    rescue StandardError => e
      puts "error = #{e.to_s}"
    end
  end

  def set_base_uri
    base_uri ENV['PHOTO_DOWNLOADER_URL']
  end
end