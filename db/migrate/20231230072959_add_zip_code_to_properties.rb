class AddZipCodeToProperties < ActiveRecord::Migration[7.1]
  def change
    add_column :properties, :zip_code, :string
  end
end
