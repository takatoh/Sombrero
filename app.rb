#
#  Sombrero Web App.
#


require "sinatra/base"
require "sequel"
require "sequel/extensions/pagination"
require "tilt/haml"
require "tilt/sass"
require "json"

require "./boot"
require "version"
require "model"
require "photo_registrar"
require_relative "routes/view"
require_relative "routes/api"


class SombreroApp < Sinatra::Base

  set :run, true

  enable :static
  set :public_dir, File.dirname(__FILE__) + "/public"
  enable :methodoverride
  enable :sessions


  # Static files

  get "/images/photos/*" do
    send_file "#{SOMBRERO_CONFIG["storage"]}/photos/#{params[:splat][0]}"
  end

  get "/images/samples/*" do
    send_file "#{SOMBRERO_CONFIG["storage"]}/samples/#{params[:splat][0]}"
  end

  get "/images/thumbs/*" do
  #   content_type "image/jpeg"
    send_file "#{SOMBRERO_CONFIG["storage"]}/thumbs/#{params[:splat][0]}"
  end

  # Views
  use SombreroView

  # API
  use SombreroAPI

end
