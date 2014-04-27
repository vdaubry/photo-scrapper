require 'rubygems'
require 'bundler/setup'
require 'yaml'
require 'dotenv'
require 'raven'

require_relative '../config/application'
require_relative '../models/scrapping'

class ScrapperConf
  def self.load
    Dotenv.load(
      File.expand_path("../../.#{APP_ENV}.env", __FILE__),
      File.expand_path("../../private-conf/.env",  __FILE__))

    Raven.configure do |config|
      config.dsn = 'https://7b018175a7d346a78950f2e90b11964d:b0f0a5bf6dec47579bb30d464fd52bb9@app.getsentry.com/22092'
    end
  end
end