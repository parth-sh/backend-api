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
