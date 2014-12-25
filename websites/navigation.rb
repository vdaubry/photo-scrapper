module Navigation
  def home_page
    agent = Mechanize.new
    agent.user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:31.0) Gecko/20100101 Firefox/31.0"
    @current_page = agent.get(url)
  end

  def sign_in(user, password)
    sign_in_page = @current_page.links.find { |l| l.text == 'Log-in' }.click
    @current_page = sign_in_page.form_with(:name => nil) do |form|
      form.fields.second.value = user
      form.fields.third.value = password
    end.submit
  end

  def category_forums(category_name)
    begin
      @current_page.link_with(:text => category_name).try(:click)
    rescue Net::HTTP::Persistent::Error => e
      puts "error : #{e.to_s}"
    end
  end

end