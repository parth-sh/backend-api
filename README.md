## Property Homepage feature
rails g model property name:string headline:string description:text city:string state:string country:string
rails db:migrate
rails g migration add_address_columns_to_properties address_1:string address_2:string
rails db:migrate
rails db:seed
Added 'faker' gem to Gemfile

## Geolocation feature
gem 'geocoder'
rails g migration add_latitude_and_longitude_to_properties latitude:float longitude:float
rails db:migrate
Added geocoded_by to properties model
rails g migration add_zip_code_to_properties zip_code:string
rails db:migrate

## Getting geolocation from profile address
rails g model profile user:references address_1:string address_2:string city:string state:string country:string latitude:float longitude:float
rails db:migrate
rails g migration add_zip_code_to_profiles zip_code:string
rails db:migrate

## Adding money to properties
gem 'money-rails'
bundle install
rails g money_rails:initializer
rails g migration add_price_cents_to_properties
rails db:migrate

## Add Active storage
image_processing gem. Uncomment it in your Gemfile
bin/rails active_storage:install
bin/rails db:migrate
config.active_storage.service = :local
