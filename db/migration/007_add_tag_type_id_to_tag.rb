class AddTagTypeIdToTag < Sequel::Migration
  def up
    alter_table :tags do
      add_column :tag_type_id,  Integer
    end
  end

  def down
    alter_table :tags do
      drop_column :tag_type_id
    end
  end
end


