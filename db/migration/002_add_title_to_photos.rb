class AddTitleToPhotos < Sequel::Migration
  def up
    alter_table :photos do
      add_column :title, :string
      add_column :note,  :text
    end
  end

  def down
    alter_table :photos do
      drop_column :title
      drop_column :note
    end
  end
end


