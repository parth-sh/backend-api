class AddZipCodeToProfiles < ActiveRecord::Migration[7.1]
  def change
    add_column :profiles, :zip_code, :string
  end
end
