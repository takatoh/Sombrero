class AddSha256ToPhoto < Sequel::Migration
  def up
    alter_table :photos do
      add_column :sha256,  String
    end
  end

  def down
    alter_table :photos do
      drop_column :sha256
    end
  end
end


