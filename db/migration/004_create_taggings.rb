class CreateTaggings < Sequel::Migration
  def up
    create_table :taggings do
      primary_key :id
      integer     :photo_id
      integer     :tag_id
    end
  end

  def down
    drop_table :taggings
  end
end


