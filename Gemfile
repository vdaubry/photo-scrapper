source 'https://rubygems.org'

gem 'httparty',                 '~> 0.13.1'
gem 'mail',                     git: 'git://github.com/pwnall/mail', :ref => 'd367c0827b10161d7cc42fd22237daa9a7cedafd' #Fixes mail dependency with mimetypes 1.x which conflicts with Mechanize dependency on mimetypes 2.x => https://github.com/mikel/mail/issues/641
gem 'mechanize',                '~> 2.7.3'
gem "activesupport",            '~> 4.1.0'
gem 'fastimage',                '~> 1.6.1'
gem 'mini_magick',              '~> 3.7.0'
gem 'net-sftp',                 '~> 2.1.2'
gem 'open_uri_redirections',    '~> 0.1.4'
gem 'dotenv',                   '~> 0.11.1'
gem 'progressbar',              '~> 0.21.0'
gem 'retriable',                '~> 1.4.1'
gem 'activemodel',              '~> 4.1.0'
gem 'image_optim',              '~> 0.13.2'


group :test do
  gem 'coveralls',              '~> 0.7.0', require: false
  gem 'rspec',                  '~> 2.14.1'
  gem 'factory_girl',           '~> 4.4.0'
  gem 'mocha',                  '~> 1.0.0'
  gem 'webmock',                '~> 1.17.4'
  gem 'vcr',                    '~> 2.9.0'
end

group :development do
  gem 'capistrano',             '~> 3.2.1'
  gem 'capistrano-bundler',     '~> 1.1.2'
end