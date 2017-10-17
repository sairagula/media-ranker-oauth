class AddForeignKeyBetweenUserAndWork < ActiveRecord::Migration[5.0]
  def change
    remove_column :works, :user_id
    add_column :works, :user_id, :integer
    add_foreign_key :works, :users
  end
end
