class AddUniqueIndexToFavourites < ActiveRecord::Migration[7.1]
  def change
    add_column :favourites, :property, :string
    add_index :favourites, [:property_id, :user_id], unique: true
  end
end
