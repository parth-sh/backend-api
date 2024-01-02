class AddUniqueIndexToReservations < ActiveRecord::Migration[7.1]
  def change
    add_index :reservations, [:property_id, :user_id, :reservation_date], unique: true
  end
end
