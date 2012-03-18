class AddAliasToTag < Sequel::Migration
  def up
    alter_table :tags do
      add_column :alias_to,  Integer
      add_column :has_alias, TrueClass, :default => false
    end
  end

  def down
    alter_table :tags do
      drop_column :alias_to
      drop_column :has_alias
    end
  end
end


