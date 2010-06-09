#
#  Sombrero Web App.
#


require 'rubygems'
require 'sinatra/base'
require 'sequel/extensions/pagination'

require 'boot'
require 'model/photo'
require 'photo_registrar'
require 'version'


class SombreroApp < Sinatra::Base

  helpers do
    include Rack::Utils
    alias_method :h, :escape_html
  end

  set :run, true

  enable :static
  set :public, File.dirname(__FILE__) + "/public"
  enable :methodoverride
  enable :sessions


  # Root

  get '/' do
    redirect '/recent/1'
  end

  # Style sheet

  get '/css/:style.css' do
    content_type 'text/css', :charset => 'utf-8'
    sass params[:style].intern
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
    @page = ::Post.order_by(:id.desc).paginate(params[:page].to_i, 10)
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
    @page = ::Post.order_by(:id.desc).paginate(params[:page].to_i, 20)
    @posts = @page.all
    @styles = %w( css/base css/list )
    @pg = params[:page]
    session["page"] = params[:page]
    haml :list
  end


  # List photos with size.

  get '/wallpapers/:size' do
    @styles = %w( css/base )
    redirect "/wallpapers/#{params[:size]}/1"
  end

  get '/wallpapers/:size/:page' do
    @size = params[:size]
    m = /\A(\d+)x(\d+)\z/.match(@size)
    w = m[1].to_i
    h = m[2].to_i
    @page = ::Photo.filter(:width => w, :height => h).order_by(:id.desc).paginate(params[:page].to_i, 20)
    @photos = @page.all
    @styles = %w( css/base )
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
    begin
      registrar = PhotoRegistrar.new( :force => params[:force] )
      registrar.clip({ :url => params[:url], :page_url => params[:page_url] })
      redirect '/'
    rescue PhotoRegistrar::Rejection => e
      @md5 = /\((.+)\)/.match(e.message)[1]
      haml :already_exist
#      redirect '/'
    end
  end


  # Post a new photo.

  get '/post/new' do
    @styles = %w( css/base )
    haml :newpost
  end

  post '/post' do
    begin
      if params[:file]
        new_filename = params[:file][:filename]
        save_file = './tmp/' + new_filename
        File.open(save_file, 'wb'){ |f| f.write(params[:file][:tempfile].read) }
        registrar = PhotoRegistrar.new( :force => params[:force] )
        registrar.post(save_file, { :url => params[:url], :page_url => params[:page_url] })
        redirect '/'
      end
    rescue PhotoRegistrar::Rejection => e
      @md5 = /\((.+)\)/.match(e.message)[1]
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
    @styles = %w( css/base css/photo )
    haml :photo
  end

  get '/photo/md5/:md5' do
    @photo = Photo.find(:md5 => params[:md5])
    @posts = @photo.posts
    @styles = %w( css/base css/photo )
    haml :photo
  end

end
