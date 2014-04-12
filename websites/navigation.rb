module Navigation
  def home_page
    @current_page = Mechanize.new.get(url)
  end

  def sign_in(user, password)
    sign_in_page = @current_page.links.find { |l| l.text == 'Log-in' }.click
    @current_page = sign_in_page.form_with(:name => nil) do |form|
      form.fields.second.value = user
      form.fields.third.value = password
    end.submit
  end

  def category_forums(category_name)
    @current_page.link_with(:text => category_name).click
  end

end