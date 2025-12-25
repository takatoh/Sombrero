#
#  Sombrero Web App: API
#

require "sinatra/base"
require "sequel"
require "json"

require "version"
require "model"
require "photo_registrar"
require_relative "../boot"


class SombreroAPI < Sinatra::Base

  get "/api/photo/:id" do
    @photo = Photo.find(:id => params[:id].to_i)
    photo_endpoint = SOMBRERO_CONFIG["hosturl"] + "images"
    data = [{
      "id"       => @photo.id,
      "width"    => @photo.width,
      "height"   => @photo.height,
      "fileSize" => @photo.filesize,
      "md5"      => @photo.md5,
      "sha256"   => @photo.sha256,
      "fileName" => File.basename(@photo.path),
      "fileUrl"  => "#{photo_endpoint}/#{@photo.path}",
      "sources"  => @photo.posts.map{|p| p.url },
      "tags"     => @photo.taggings.map{|t| t.tag.name }
    }]
    content_type :json
    data.to_json
  end

  get "/api/photos" do
    limit = params[:limit] ? params[:limit].to_i : 20
    offset = params[:offset] ? params[:offset].to_i : 0
    @photos = Photo.dataset.limit(limit).offset(offset)
    photo_endpoint = SOMBRERO_CONFIG["hosturl"] + "images"
    data = @photos.map do |p|
      {
        "id"       => p.id,
        "width"    => p.width,
        "height"   => p.height,
        "fileSize" => p.filesize,
        "md5"      => p.md5,
        "sha256"   => p.sha256,
        "fileName" => File.basename(p.path),
        "fileUrl"  => "#{photo_endpoint}/#{p.path}",
        "sources"  => p.posts.map{|post| post.url },
        "tags"     => p.taggings.map{|t| t.tag.name }
      }
    end
    content_type :json
    data.to_json
  end

  get "/api/photo/md5/:md5" do
    @photo = Photo.find(:md5 => params[:md5])
    photo_endpoint = SOMBRERO_CONFIG["hosturl"] + "images"
    data = [{
      "id"       => @photo.id,
      "width"    => @photo.width,
      "height"   => @photo.height,
      "fileSize" => @photo.filesize,
      "md5"      => @photo.md5,
      "sha256"   => @photo.sha256,
      "fileName" => File.basename(@photo.path),
      "fileUrl"  => "#{photo_endpoint}/#{@photo.path}",
      "sources"  => @photo.posts.map{|p| p.url },
      "tags"     => @photo.taggings.map{|t| t.tag.name }
    }]
    content_type :json
    data.to_json
  end

  get "/api/post/:id" do
    @post = Post.find(:id => params[:id].to_i)
    data = [{
      "id"      => @post.id,
      "source"  => @post.url,
      "webPage" => @post.page_url,
      "title"   => @post.title,
      "photoId" => @post.photo_id
    }]
    content_type :json
    data.to_json
  end

  get "/api/posts" do
    limit = params[:limit] ? params[:limit].to_i : 20
    offset = params[:offset] ? params[:offset].to_i : 0
    @posts = Post.dataset.limit(limit).offset(offset)
    data = @posts.map do |p|
      {
        "id"         => p.id,
        "source"     => p.url,
        "webPage"    => p.page_url,
        "title"      => p.title,
        "photoId"    => p.photo_id,
        "postedDate" => p.posted_date
      }
    end
    content_type :json
    data.to_json
  end

  post "/api/post" do
    begin
      if params[:file]
        new_filename = params[:file][:filename]
        save_file = "./tmp/" + new_filename
        File.open(save_file, "wb"){ |f| f.write(params[:file][:tempfile].read) }
        registrar = PhotoRegistrar.new( :force => params[:force] )
        photo = registrar.post(
          save_file,
          {
            :url      => params[:url],
            :page_url => params[:page_url],
            :tags     => params[:tags]
          }
        )
        data = {
          "status" => "Accepted",
          "photo" => {
            "id"       => photo.id,
            "width"    => photo.width,
            "height"   => photo.height,
            "fileSize" => photo.filesize,
            "md5"      => photo.md5,
            "sha256"   => photo.sha256,
            "fileName" => File.basename(photo.path)
          }
        }
      end
    rescue PhotoRegistrar::TooSmall => e
      #message = e.message
      #case message
      #when /Small photo/
        data = {
          "status" => "Rejected",
          "reason" => "Small photo"
        }
    rescue PhotoRegistrar::PhotoExists => e
      #when /Already/
        photo = e.details[:photo]
        tags = if params[:add_tags]
          photo.add_tags(params[:tags]).map{|t| t.name}
        else
          []
        end
        if tags.empty?
          data = {
            "status" => "Rejected",
            "reason" => "Already exist",
            "photo" => {
              "id"       => photo.id,
              "width"    => photo.width,
              "height"   => photo.height,
              "fileSize" => photo.filesize,
              "md5"      => photo.md5,
              "sha256"   => photo.sha256,
              "fileName" => File.basename(photo.path)
            }
          }
        else
          data = {
            "status" => "Added tags",
            "photo" => {
              "id"        => photo.id,
              "width"     => photo.width,
              "height"    => photo.height,
              "fileSize"  => photo.filesize,
              "md5"       => photo.md5,
              "sha256"    => photo.sha256,
              "fileName"  => File.basename(photo.path),
              "addedTags" => tags
            }
          }
        end
      #end
    end
    content_type :json
    data.to_json
  end

  post "/api/clip" do
    begin
      registrar = PhotoRegistrar.new( :force => params[:force] )
      photo = registrar.clip(
        {
          :url      => params[:url],
          :page_url => params[:page_url],
          :tags     => params[:tags]
        }
      )
      data = {
        "status" => "Accepted",
        "photo" => {
          "id"       => photo.id,
          "width"    => photo.width,
          "height"   => photo.height,
          "fileSize" => photo.filesize,
          "md5"      => photo.md5,
          "sha256"   => photo.sha256,
          "fileName" => File.basename(photo.path)
        }
      }
    rescue PhotoRegistrar::Rejection => e
      message = e.message
      case message
      when /Small photo/
        data = {
          "status" => "Rejected",
          "reason" => "Small photo"
        }
      when /Already/
        md5 = /\((.+)\)/.match(e.message)[1]
        photo = Photo.find(:md5 => md5)
        tags = if params[:add_tags]
          photo.add_tags(params[:tags]).map{|t| t.name}
        else
          []
        end
        if tags.empty?
          data = {
            "status" => "Rejected",
            "reason" => "Already exist",
            "photo" => {
              "id"       => photo.id,
              "width"    => photo.width,
              "height"   => photo.height,
              "fileSize" => photo.filesize,
              "md5"      => photo.md5,
              "sha256"   => photo.sha256,
              "fileName" => File.basename(photo.path)
            }
          }
        else
          data = {
            "status" => "Added tags",
            "photo" => {
              "id"        => photo.id,
              "width"     => photo.width,
              "height"    => photo.height,
              "fileSize"  => photo.filesize,
              "md5"       => photo.md5,
              "sha256"    => photo.sha256,
              "fileName"  => File.basename(photo.path),
              "addedTags" => tags
            }
          }
        end
      end
    end
    content_type :json
    data.to_json
  end

  get "/api/statistics" do
    photo_count = Photo.count
    post_count = Post.count
    data = {
      "statistics" => {
        "photos" => photo_count,
        "posts"  => post_count
      }
    }
    content_type :json
    data.to_json
  end

end
