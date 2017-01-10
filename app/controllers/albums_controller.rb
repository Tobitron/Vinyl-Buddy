class AlbumsController < ApplicationController
  
  before_filter do
    @discogs = Discogs::Wrapper.new("Vinyl Buddy", session[:access_token])
  end

  def index
    if params_exist?(params)
      @artist = params["artist"]
      @album = params["album"]

      get_data(@artist, @album)
    end
  end

  # Add an action to initiate the process.
  def authenticate
    request_data = @discogs.get_request_token("RaPgRAkAJmTPsuBhOZdS", "UunGpzpdipAuAKpNlCIXkbdypqvMDHLC", "http://127.0.0.1:3000/callback")

    session[:request_token] = request_data[:request_token]
    redirect_to request_data[:authorize_url]
  end

  # And an action that Discogs will redirect back to.
  def callback
    binding.pry
    request_token = session["oauth_token"]
    verifier      = params[:oauth_verifier]
    access_token  = @discogs.authenticate(request_token, verifier)

    session[:request_token] = nil
    session[:access_token]  = access_token

    @discogs.access_token = access_token
    redirect_to :action => "index"


    # You can now perform authenticated requests.
  end


  def params_exist?(params)
    params["artist"] == nil ? false : true
  end

  def get_data(artist, album)

    wrapper = Discogs::Wrapper.new("Vinyl Buddy", user_token: ENV['DISCOGS_USER_TOKEN'])

    discogs_search = wrapper.search("#{@artist} - #{@album}")
    vinyl = []


    discogs_search.results.each do |album|
      unless album.format.nil?
        vinyl << album if album.format[0] == "Vinyl"
      end
    end

    if vinyl[0].type == "release"
      release = vinyl[0].id
    else
      release = vinyl[1].id
    end

    agent = Mechanize.new do |a|
      a.user_agent_alias = 'Mac Safari'
    end


    # Find discogs price
    login_page = agent.get "http://www.discogs.com/sell/history/#{release}"


    username_form = login_page.forms[0].field_with(name: "username")
    password_form = login_page.forms[0].field_with(name: "password")

    username_form.value = ENV['DISCOGS_USER_NAME']
    password_form.value = ENV['DISCOGS_PASSWORD']

    agent.submit(login_page.forms[0], login_page.forms[0].buttons.first)

    price_data = agent.page.css('div.clearfix li')

    @price_data = price_data[1].text[21 .. 26]

    # Find allmusic album rating
    agent.get "http://www.allmusic.com/search/albums/#{@artist}+#{@album}"

    
    # agent.page.link_with(text: "#{album}").click <-- this only works if cases are exactly perfect
    album_link = "http://www.allmusic.com" + agent.page.css("li.album")[0].children.children[1].attributes["href"].value
    agent.get(album_link)
    rating_div = agent.page.search('div.allmusic-rating')
    @album_rating = rating_div[0].children.text.strip
  end
end
