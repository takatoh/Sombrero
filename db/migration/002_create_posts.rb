class CreatePosts < Sequel::Migration
  def up
    create_table :posts do
      primary_key :id
      string      :url
      string      :page_url
      string      :title
      text        :note

      integer     :photo_id

      timestamp   :posted_date
    end
  end

  def down
    drop_table :posts
  end
end


