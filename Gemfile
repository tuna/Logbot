
source 'https://rubygems.org'

gem 'jellyfish' # web
gem 'cinch'     # agent
gem 'redis'     # used in web and agent

# All of below are optional/selectional:
group :server do
  platform(:ruby) do
    gem 'rainbows'
  end

  platform(:jruby) do
    gem 'trinidad'
  end
end

# compile assets
group :assets do
  gem 'compass'
  gem 'sass'
end
