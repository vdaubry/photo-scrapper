class WebsiteScrapper
  def initialize(scrapper)
    @scrapper = scrapper
  end

  def start
    start_time = DateTime.now
    scrapping = @scrapper.create_scrapping
    @scrapper.home_page
    @scrapper.authorize
    @scrapper.do_scrap
    @scrapper.end_scrapping(scrapping, DateTime.now-start_time)
  end
end