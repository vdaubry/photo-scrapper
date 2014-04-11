module ScrappingDate
  def last_scrapping_date
    scrapping_date.nil? ? 1.month.ago.beginning_of_month : scrapping_date
  end

  def previous_month
    scrapping_date.nil? ? 1.month.ago.beginning_of_month : (scrapping_date - 1.month).beginning_of_month
  end

  def next_month
    scrapping_date.nil? ? 1.month.ago.beginning_of_month : (scrapping_date + 1.month).beginning_of_month
  end 
end