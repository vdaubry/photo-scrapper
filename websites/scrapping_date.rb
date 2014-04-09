module ScrappingDate
  def scrapping_date
    last_scrapping_date.nil? ? 1.month.ago.beginning_of_month : last_scrapping_date
  end

  def previous_month
    last_scrapping_date.nil? ? 1.month.ago.beginning_of_month : (last_scrapping_date - 1.month).beginning_of_month
  end

  def next_month
    last_scrapping_date.nil? ? 1.month.ago.beginning_of_month : (last_scrapping_date + 1.month).beginning_of_month
  end 
end