module Scrapping
  def last_scrapping_date
    @website.last_scrapping_date.nil? ? 1.month.ago.beginning_of_month : @website.last_scrapping_date
  end

  def previous_month
    @website.last_scrapping_date.nil? ? 1.month.ago.beginning_of_month : (@website.last_scrapping_date - 1.month).beginning_of_month
  end

  def next_month
    @website.last_scrapping_date.nil? ? 1.month.ago.beginning_of_month : (@website.last_scrapping_date + 1.month).beginning_of_month
  end 
end