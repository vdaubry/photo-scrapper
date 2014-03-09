module Navigation
  def home_page
    @current_page = Mechanize.new.get(@website.url)
  end
end