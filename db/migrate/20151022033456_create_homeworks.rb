class CreateHomeworks < ActiveRecord::Migration
  def change
    create_table :homeworks do |t|
      t.string :hw_name
      t.text :hw_description
      t.datetime :hw_release_time
      t.datetime :hw_due_time
      t.string :hw_test_case_dir, limit: 2047

      t.timestamps null: false
    end
  end
end
