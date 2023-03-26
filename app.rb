#
#  Sombrero Web App.
#


require 'sinatra/base'
require 'sequel'
require 'sequel/extensions/pagination'
require 'tilt/haml'
require 'tilt/sass'
require 'json'

require './boot'
require 'version'
require 'model'
require 'photo_registrar'


class SombreroApp < Sinatra::Base

  helpers do
    include Rack::Utils
    alias_method :h, :escape_html

    def link_to_hostname(url)
      unless url.nil? || url.empty?
        hostname = URI.parse(url).host
        %Q[<a href="#{url}">#{hostname}</a>]
      else
        ""
      end
    end

    def hostname(url)
      unless url.nil? || url.empty?
        URI.parse(url).host
      else
        ""
      end
    end

  end

  set :run, true

  enable :static
  set :public_dir, File.dirname(__FILE__) + "/public"
  enable :methodoverride
  enable :sessions


  # Root

  get '/' do
    redirect '/recent/1'
  end

  #

  get '/images/photos/*' do
    send_file "#{SOMBRERO_CONFIG["storage"]}/photos/#{params[:splat][0]}"
  end

  get '/images/samples/*' do
    send_file "#{SOMBRERO_CONFIG["storage"]}/samples/#{params[:splat][0]}"
  end

  get '/images/thumbs/*' do
  #   content_type "image/jpeg"
    send_file "#{SOMBRERO_CONFIG["storage"]}/thumbs/#{params[:splat][0]}"
  end


  # Recent posts.

  get '/recent/:page' do
    @page = ::Post.reverse_order(:id).extension(:pagination).paginate(params[:page].to_i, 10)
    @posts = @page.all
    @styles = %w( css/base css/recent js/highslide/highslide )
    @pg = params[:page]
    session["page"] = params[:page]
    haml :recent
  end


  # List posts.

  get '/list' do
    redirect '/list/1'
  end

  get '/list/:page' do
    @page = ::Photo.reverse_order(:id).extension(:pagination).paginate(params[:page].to_i, 20)
    @photos = @page.all
    @styles = %w( css/base css/list )
    @pg = params[:page]
    session["page"] = params[:page]
    haml :list
  end


  # List photos with size.

  get '/wallpapers/:size' do
    redirect "/wallpapers/#{params[:size]}/1"
  end

  get '/wallpapers/:size/:page' do
    @size = params[:size]
    m = /\A(\d+)x(\d+)\z/.match(@size)
    w = m[1].to_i
    h = m[2].to_i
    @page = ::Photo.filter(:width => w, :height => h).reverse_order(:id).extension(:pagination).paginate(params[:page].to_i, 20)
    @photos = @page.all
    @styles = %w( css/base css/list )
    @pg = params[:page]
    session["page"] = params[:page]
    haml :wallpapers
  end


  # Clip a new photo.

  get '/clip/new' do
    @styles = %w( css/base )
    haml :newclip
  end

  post '/clip' do
    @styles = %w( css/base css/mini_photo )
    registrar = PhotoRegistrar.new( :force => params[:force] )
    registrar.clip(
      {
        :url      => params[:url],
        :page_url => params[:page_url],
        :tags     => params[:tags]
      }
    )
    redirect '/'
  rescue FileFetcher::FetchError => e
    @url = params[:url]
    @page_url = params[:page_url]
    @tags = params[:tags]
    @force = params[:force]
    haml :clip_failure
  rescue PhotoRegistrar::Rejection => e
    @message = e.message
    @url = e.details[:url]
    @page_url = e.details[:page_url]
    @tags = e.details[:tags]
    @url_posted = e.details[:url_posted]
    @md5 = e.details[:md5]
    @photo = e.details[:photo]
    haml :already_exist
  end


  # Post a new photo.

  get '/post/new' do
    @styles = %w( css/base )
    haml :newpost
  end

  post '/post' do
    @styles = %w( css/base css/mini_photo )
    if params[:file]
      new_filename = params[:file][:filename]
      save_file = './tmp/' + new_filename
      File.open(save_file, 'wb'){ |f| f.write(params[:file][:tempfile].read) }
      registrar = PhotoRegistrar.new( :force => params[:force] )
      registrar.post(
        save_file,
        {
          :url      => params[:url],
          :page_url => params[:page_url],
          :tags     => params[:tags]
        }
      )
      redirect '/'
    end
  rescue PhotoRegistrar::Rejection => e
    @message = e.message
    case @message
    when /Small photo/
      redirect '/recent/1'
    when /Already/
      @url = e.details[:url]
      @page_url = e.details[:page_url]
      @tags = e.details[:tags]
      @url_posted = e.details[:url_posted]
      @md5 = e.details[:md5]
      @photo = e.details[:photo]
      haml :already_exist
    end
  end


  # Edit photo information.

#  get '/photo/:id.edit' do
#    @post = Post.find(:id => params[:id])
#    haml :editphoto
#  end

  post '/photo/:id.edit' do
    @post = Post.find(:id => params[:id])
    @styles = %w( css/base )
    haml :editphoto, :layout => false
  end

  put '/photo/:id' do
    @post = Post.find(:id => params[:id])
    @post.title = params[:title]
    @post.note = params[:note]
    @post.save
    redirect "/recent/#{session["page"]}"
  end

  get '/photo/:id.delete' do
    @post = Post.find(:id => params[:id])
    @post.destroy
    redirect "/recent/#{session["page"]}"
  end

  post '/photo/update-tags' do
    @photo = Photo.find(:id => params[:id])
    @photo.update_tags(params[:tags])
    redirect "/photo/#{@photo.id}"
  end


  # Edit and delete post.

  post '/post/:id.edit' do
    @post = Post.find(:id => params[:id])
    @styles = %w( css/base )
    haml :editpost, :layout => false
  end

  put '/post/:id' do
    @post = Post.find(:id => params[:id])
    @post.title = params[:title]
    @post.note = params[:note]
    @post.save
    @photo = @post.photo
    @photo.update_tags(params[:tags])
    @photo.save
    redirect "/recent/#{session["page"]}"
  end

  get '/post/:id.delete' do
    @post = Post.find(:id => params[:id])
    @post.destroy
    redirect "/recent/#{session["page"]}"
  end


  # Show photo.

  get '/photo/:id' do
    @photo = Photo.find(:id => params[:id])
    @posts = @photo.posts
    unless @photo.has_ext?
      extname = @posts.map{|p| p.extname }.first
      @photo.put_ext(extname)
    end
    @tags = @photo.taggings.map{|t| t.tag}
    @styles = %w( css/base css/photo )
    haml :photo
  end

  get '/photo/md5/:md5' do
    @photo = Photo.find(:md5 => params[:md5])
    @posts = @photo.posts
    @tags = @photo.taggings.map{|t| t.tag}
    @styles = %w( css/base css/photo )
    haml :photo
  end


  # Listing tags.

  get '/tags/:page' do
    @page = ::Tag.order(:name).extension(:pagination).paginate(params[:page].to_i, 25)
    @tags = @page.all
    @styles = %w( css/base css/tag_list )
    session["page"] = params[:page]
    haml :tag_list
  end

  get '/tags/edit/:id' do
    @tag = ::Tag.find(:id => params[:id])
    @styles = %w( css/base css/tag_list )
    @tag_type_name = if @tag.tag_type then @tag.tag_type.name else "" end
    haml :tag_edit
  end

  put '/tags/edit/:id' do
    @tag = ::Tag.find(:id => params[:id])
    @styles = %w( css/base css/tag_list )
    @tag.name = params[:name]
    @tag.description = params[:description]
    unless params[:tagtype].empty?
      tag_type = ::TagType.find(:name => params[:tagtype])
      @tag.tag_type_id = tag_type.id if tag_type
    end
    @tag.save
    pg = session["page"]
    redirect "/tags/#{pg}"
  end

  # Listing tag types.

  get '/tagtypes/new' do
    @styles = %w( css/base css/tag_type_list )
    haml :tag_type_new
  end

  post '/tagtypes/new' do
    @styles = %w( css/base css/tag_type_list )
    ::TagType.create(:name => params[:name], :description => params[:description])
    redirect "/tagtypes/1"
  end

  get '/tagtypes/:page' do
    @page = ::TagType.order_by(:id).extension(:pagination).paginate(params[:page].to_i, 25)
    @tagtypes = @page.all
    @styles = %w( css/base css/tag_type_list)
    session["page"] = params[:page]
    haml :tag_type_list
  end

  get '/tagtypes/edit/:id' do
    @tag_type = ::TagType.find(:id => params[:id])
    @styles = %w( css/base css/tag_type_list )
    haml :tag_type_edit
  end

  put '/tagtypes/edit/:id' do
    @tag_type = ::TagType.find(:id => params[:id])
    @styles = %w( css/base css/tag_type_list )
    @tag_type.name = params[:name]
    @tag_type.description = params[:description]
    @tag_type.save
    pg = session["page"]
    redirect "/tagtypes/#{pg}"
  end


  # Web API

  get '/api/photo/:id' do
    @photo = Photo.find(:id => params[:id].to_i)
    photo_endpoint = SOMBRERO_CONFIG["hosturl"] + "images"
    data = [{
      "id"       => @photo.id,
      "width"    => @photo.width,
      "height"   => @photo.height,
      "fileSize" => @photo.filesize,
      "md5"      => @photo.md5,
      "fileName" => File.basename(@photo.path),
      "fileUrl"  => "#{photo_endpoint}/#{@photo.path}",
      "sources"  => @photo.posts.map{|p| p.url },
      "tags"     => @photo.taggings.map{|t| t.tag.name }
    }]
    content_type :json
    data.to_json
  end

  get '/api/photos' do
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
        "fileName" => File.basename(p.path),
        "fileUrl"  => "#{photo_endpoint}/#{p.path}",
        "sources"  => p.posts.map{|post| post.url },
        "tags"     => p.taggings.map{|t| t.tag.name }
      }
    end
    content_type :json
    data.to_json
  end

  get '/api/photo/md5/:md5' do
    @photo = Photo.find(:md5 => params[:md5])
    photo_endpoint = SOMBRERO_CONFIG["hosturl"] + "images"
    data = [{
      "id"       => @photo.id,
      "width"    => @photo.width,
      "height"   => @photo.height,
      "fileSize" => @photo.filesize,
      "md5"      => @photo.md5,
      "fileName" => File.basename(@photo.path),
      "fileUrl"  => "#{photo_endpoint}/#{@photo.path}",
      "sources"  => @photo.posts.map{|p| p.url },
      "tags"     => @photo.taggings.map{|t| t.tag.name }
    }]
    content_type :json
    data.to_json
  end

  get '/api/post/:id' do
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

  get '/api/posts' do
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

  post '/api/post' do
    begin
      if params[:file]
        new_filename = params[:file][:filename]
        save_file = './tmp/' + new_filename
        File.open(save_file, 'wb'){ |f| f.write(params[:file][:tempfile].read) }
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
            "fileName" => File.basename(photo.path)
          }
        }
      end
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

  post '/api/clip' do
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

  get '/api/statistics' do
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
