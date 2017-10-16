class AddNullToUserFields < ActiveRecord::Migration[5.0]
  def change
    change_column :users, :provider, :string, null: false
    change_column :users, :uid, :string, null: false
  end
end
