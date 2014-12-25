require_relative '../models/scrapping'

class WebsiteScrapper

  def initialize(scrapper)
    @scrapper = scrapper
  end

  def start
    Raven.capture do
      @scrapper.home_page
      @scrapper.authorize
      @scrapper.do_scrap
    end
  end
end