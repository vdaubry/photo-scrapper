source 'https://rubygems.org'

gem 'httparty',                 '~> 0.13.1'
gem 'mail',                     git: 'git://github.com/pwnall/mail', :ref => 'd367c0827b10161d7cc42fd22237daa9a7cedafd' #Fixes mail dependency with mimetypes 1.x which conflicts with Mechanize dependency on mimetypes 2.x => https://github.com/mikel/mail/issues/641
gem 'mechanize',                '~> 2.7.3'
gem 'activesupport',            '~> 4.1.6'
gem 'activemodel',              '~> 4.1.6'
gem 'dotenv',                   '~> 0.11.1'
gem 'retriable',                '~> 1.4.1'
gem 'sentry-raven',             '~> 0.10.1'
gem 'aws-sdk',                  '~> 1.54.0'

group :test do
  gem 'coveralls',              '~> 0.7.1', require: false
  gem 'rspec',                  '~> 3.1.0'
  gem 'factory_girl',           '~> 4.4.0'
  gem 'mocha',                  '~> 1.1.0'
  gem 'webmock',                '~> 1.19.0'
  gem 'vcr',                    '~> 2.9.3'
end

group :development do
  gem 'capistrano',             '~> 3.2.1'
  gem 'capistrano-bundler',     '~> 1.1.3'
end