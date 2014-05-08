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
      config.dsn = ENV['RAVEN_URL']
    end
  end
end