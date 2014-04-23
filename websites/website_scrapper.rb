require_relative '../models/scrapping'

class WebsiteScrapper
  def initialize(scrapper)
    @scrapper = scrapper
  end

  def start
    begin
      start_time = DateTime.now
      scrapping_date = @scrapper.scrapping_date
      pp "Start scrapping #{@scrapper.url} for month : #{scrapping_date}"
      scrapping = Scrapping.create(@scrapper.id, scrapping_date)

      @scrapper.home_page
      @scrapper.authorize
      @scrapper.do_scrap

      duration = DateTime.now-start_time
      pp "End scrapping #{@scrapper.url} with duration : #{duration}"
      Scrapping.update(@scrapper.id, scrapping.id, {:success => true, :duration => duration})
    rescue StandardError => e
      puts "Fail for unknown reason : "+e.to_s
    ensure
      if APP_ENV == 'production'
        puts "Shutting down in env #{APP_ENV}"
        system("shutdown -h now") 
      else
        puts "Error app env = #{APP_ENV}"
        puts "APP_ENV == 'production' : #{APP_ENV == 'production'}"
      end
    end
  end
end