class CreateTagTypes < Sequel::Migration
  def up
    create_table :tag_types do
      primary_key :id
      string      :name, :unique => true
      string      :description
    end
  end

  def down
    drop_table :tag_types
  end
end


