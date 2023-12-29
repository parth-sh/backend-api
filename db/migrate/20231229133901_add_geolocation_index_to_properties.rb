class AddGeolocationIndexToProperties < ActiveRecord::Migration[7.1]
  def change
    add_index :properties, [:latitude, :longitude]
  end
end
