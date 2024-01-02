class AddAverageRatingToProperties < ActiveRecord::Migration[7.1]
  def change
    add_column :properties, :average_rating, :decimal
  end
end
