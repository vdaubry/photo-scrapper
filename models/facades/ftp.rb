require 'net/sftp'

class Ftp
  def move_files_to_keep(keys)
    Net::SFTP.start(ENV['FTP_ADRESS'], ENV['FTP_LOGIN'], :password => ENV['FTP_PASSWORD']) do |sftp|
      keys.each do |key|
        path1 = "#{ENV['IMAGES_PATH']}/#{key}"
        path2 = "#{ENV['SAVE_PATH']}/#{key}"

        sftp.rename(path1, path2)
        sftp.remove("#{ENV['THUMBNAILS_PATH']}/#{key}")
        print "."
      end
    end
  end

  def delete_files(keys)
    Net::SFTP.start(ENV['FTP_ADRESS'], ENV['FTP_LOGIN'], :password => ENV['FTP_PASSWORD']) do |sftp|
      keys.each do |key|
        sftp.remove("#{ENV['IMAGES_PATH']}/#{key}")
        sftp.remove("#{ENV['THUMBNAILS_PATH']}/#{key}")
        print "."
      end
    end
  end

  def upload_file(image)
    unless ENV['TEST']
      begin
        Net::SFTP.start(ENV['FTP_ADRESS'], ENV['FTP_LOGIN'], :password => ENV['FTP_PASSWORD']) do |sftp|
          sftp.upload!(image.image_save_path, "#{ENV['IMAGES_PATH']}/#{image.key}")
          sftp.upload!(image.thumbnail_save_path, "#{ENV['THUMBNAILS_PATH']}/#{image.key}")
        end
      rescue Errno::ECONNRESET => e
        puts "Failed to upload image #{image.key} to FTP"+e.to_s
      rescue Net::SSH::Disconnect => e
        puts "Failed to upload image #{image.key} to FTP"+e.to_s
      end
    end
  end
end