class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.string :name
      t.text :description
      t.string :url
      t.text :attributes

      t.timestamps
    end
  end
end
