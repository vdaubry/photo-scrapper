require_relative '../models/scrapping'
require_relative 'shutdown'

class WebsiteScrapper
  include Shutdown

  def initialize(scrapper)
    @scrapper = scrapper
  end

  def start
    terminate_after do
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
      puts "about to shutdown"
    end
  end
end