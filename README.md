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
Prepared seeds to attach files
rails db:reset
rails db:seed

Warning while db reset: ActiveStorage on Rails 7.0.1 forces vips #44211
https://github.com/rails/rails/issues/44211#issuecomment-1017461170
config.active_storage.variant_processor = :mini_magick
https://stackoverflow.com/questions/58120323/how-do-i-get-the-local-path-to-an-active-storage-blob

## Reviews
rails g model review
Make migration columns
Add polymorphic to review model
rails db:migrate

## Optimizing reviews model
Using :counter_cache option, in rails associations
rails g migration add_reviews_count_to_property reviews_count:integer
rails db:migrate
Added counter_cache option to review model
Property.reset_counters(Property.first.id, :reviews)
irb(main):012* Property.find_each do |property|
irb(main):013*   Property.reset_counters(property.id, :reviews)
irb(main):014> end

### Optimizing average rating
rails g migration add_average_rating_to_properties average_rating:decimal
rails db:migrate
```
def update_average_rating
    reviewable.update!(average_rating: reviewable.reviews.average(:rating))
end
```
irb(main):002> Review.find_each{|r| r.save}
