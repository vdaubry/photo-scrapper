module Shutdown

  def terminate_after
    begin
      yield
    rescue StandardError => e
      puts "Fail for unknown reason : "+e.to_s
    ensure
      if APP_ENV == 'production'
        puts "Shutting down in env #{APP_ENV}"
        system("shutdown -h now") 
      else
        puts "Error app env = #{APP_ENV}"
        puts "is env production : #{APP_ENV == 'production'}"
      end
    end
  end

end