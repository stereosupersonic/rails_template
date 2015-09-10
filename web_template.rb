# Guide http://guides.rubyonrails.org/rails_application_templates.html
# example https://github.com/Skookum/uu-rails-api-template/blob/master/rails-api-template.rb

# Gems
# ==================================================

puts "********* #{app_name} ******"
# For encrypted password
gem 'bcrypt-ruby'

# For authorization (https://github.com/ryanb/cancan)
gem 'cancan'

gem 'haml-rails'

# Simple form builder (https://github.com/plataformatec/simple_form)
gem 'simple_form', git: 'https://github.com/plataformatec/simple_form'
# To generate UUIDs, useful for various things
gem 'uuidtools'
gem 'rails_admin'

# bootstrap
gem 'bootstrap-sass', '~> 3'
gem 'rails-footnotes' # https://github.com/josevalim/rails-footnotes

gem_group :development do
  # Rspec for tests (https://github.com/rspec/rspec-rails)
  gem 'rspec-rails'
  # Guard for automatically launching your specs when files are modified. (https://github.com/guard/guard-rspec)
  gem 'guard-rspec'

  gem 'rails_layout'      # https://github.com/RailsApps/rails_layout => rails generate layout:install bootstrap3
  gem 'rails_apps_pages'  # https://github.com/RailsApps/rails_apps_pages  =>  rails generate pages:home -f

  gem 'bootstrap-generators', '~> 3.2.0'
  gem 'annotate',          git: 'git://github.com/ctran/annotate_models.git'
  gem 'g',                 git: 'https://github.com/stereosupersonic/g'
  gem 'quiet_assets' # Quiet assets turn off rails assets log.
  gem 'binding_of_caller' # is needed for better_errors
  gem 'better_errors' # https://github.com/charliesome/better_errors

  gem 'pry-rails'
  gem 'pry-rescue'
  gem 'pry-stack_explorer'
  gem 'pry-byebug'

  gem 'web-console'
end

gem_group :test do
  gem 'simplecov', require: false
  gem 'simplecov-rcov', require: false
  gem 'rspec-rails'
  # Capybara for integration testing (https://github.com/jnicklas/capybara)
  gem 'capybara'
  #gem 'capybara-webkit'
  gem 'launchy'
  # FactoryGirl instead of Rails fixtures (https://github.com/thoughtbot/factory_girl)
  gem 'factory_girl_rails'
  gem 'database_cleaner'
end

gem_group :production do
  # For Rails 4 deployment on Heroku
  gem 'rails_12factor'
  gem 'pg'
end

run 'bundle install'

# Initialize guard
# ==================================================
run 'bundle exec guard init rspec'

# Initialize CanCan
# ==================================================
run 'rails g cancan:ability'

# bootstrap

run ' rails g bootstrap:install -f --template-engine=haml'
run ' rm app/assets/javascripts/application.js'
run ' rm app/views/layouts/application.html.haml'
run ' rails g layout:install bootstrap3'
run ' rails g pages:home -f'

# rails admin
run 'rails g rails_admin:install'
# rails_footnotes
run 'rails generate rails_footnotes:install'
# Clean up Assets
# ==================================================
# Use SASS extension for application.css
run 'mv app/assets/stylesheets/application.css app/assets/stylesheets/application.css.scss'
# Remove the require_tree directives from the SASS and JavaScript files.
# It's better design to import or require things manually.
run "sed -i '' /require_tree/d app/assets/javascripts/application.js"
run "sed -i '' /require_tree/d app/assets/stylesheets/application.css.scss"
# add bootstrap
run 'echo >> app/assets/stylesheets/application.css.scss'
run "echo '@import \"bootstrap-sprockets\";' >>  app/assets/stylesheets/application.css.scss"
run "echo '@import \"bootstrap\";' >>  app/assets/stylesheets/application.css.scss"

insert_into_file 'config/application.rb', after: "require 'rails/all'\n" do
  <<-RUBY
require "active_record/railtie"
require "action_controller/railtie"
  RUBY
end

application do
  <<-RUBY
    config.generators do |g|
         g.template_engine :haml
         g.test_framework :rspec,
           :fixtures        => true,
           :view_specs      => false,
           :helper_specs    => false,
           :routing_specs   => false,
           :controller_specs => true,
           :request_specs    => false
         g.fixture_replacement :factory_girl, :dir => "spec/factories"
      end
  RUBY
end

# Database

run "rm config/database.yml"

create_file 'config/database.ym' do <<-EOF
 default: &default
   adapter: sqlite3
   pool: 5
   timeout: 5000

 development:
   <<: *default
   database: db/development.sqlite3

 # Warning: The database defined as "test" will be erased and
 # re-generated from your development database when you run "rake".
 # Do not set this db to the same as development or production.
 test:
   <<: *default
   database: db/test.sqlite3

 production:
   <<: *default
   adapter: postgresql
   encoding: unicode
   host: db
   database: #{app_name}_production
   username: postgres
EOF
end

run "cp config/database.yml config/database.yml.example"

rake "db:create"

# Ignore rails doc files, Vim/Emacs swap files, .DS_Store, and more
# ===================================================
run "cat << EOF >> .gitignore
/.bundle
/db/*.sqlite3
/db/*.sqlite3-journal
/log/*.log
/tmp
database.yml
doc/
*.swp
*~
.project
.idea
.secret
.DS_Store
EOF"

# Docker

create_file 'Dockerfile' do <<-EOF
FROM ruby:2.2.2

RUN apt-get update -yqq && apt-get install -y build-essential

EXPOSE 3000

# for postgres
RUN apt-get install -y libpq-dev

# for nokogiri
RUN apt-get install -y libxml2-dev libxslt1-dev

# for capybara-webkit
RUN apt-get install -y libqt4-webkit libqt4-dev xvfb

# some tools
RUN apt-get install -y vim

# for a JS runtime
RUN apt-get install -y nodejs

RUN mkdir /app

WORKDIR /tmp
COPY Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN bundle install --deploy

RUN echo 'Doing something...'

ADD . /app
WORKDIR /app

# Run the app in production mode by default:
ENV RACK_ENV=production RAILS_ENV=production

CMD ["rails", "server", "-b", "0.0.0.0"]
EOF
end

create_file 'docker-compose.yml' do <<-EOF
web:
  build: .
  volumes:
    - .:/app
  links:
    - db
  ports:
    - "3000:3000"
db:
  image: postgres
  volumes:
   - .:/app # We're mounting this folder so we can backup/restore database dumps from our app folder.
  ports:
    - "5432:5432"
EOF
end

run "rm README.*"

create_file 'README.md' do <<-EOF
# #{app_name}


## Docker

## build
    docker-compose build

## Run #{app_name} app in a container
    docker-compose up

EOF
end

# Git: Initialize
# ==================================================
git :init
git add: '.'
git commit: %( -m 'Initial commit' )

if yes?('Initialize GitHub repository?')
  git_uri = `git config remote.origin.url`.strip
  unless git_uri.size == 0
    say 'Repository already exists:'
    say "#{git_uri}"
  else
    username = ask 'What is your GitHub username?'
    run "curl -u #{username} -d '{\"name\":\"#{app_name}\"}' https://api.github.com/user/repos"
    git remote: %( add origin git@github.com:#{username}/#{app_name}.git )
    git push: %( origin master )
  end
end