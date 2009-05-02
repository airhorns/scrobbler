# Probably the most common use of this lib would be to get your most recent tracks or your top tracks. Below are some code samples.
#   user = Scrobbler::User.new('jnunemaker')
# 
#   puts "#{user.username}'s Recent Tracks"
#   puts "=" * (user.username.length + 16)
#   user.recent_tracks.each { |t| puts t.name }
# 
#   puts
#   puts
# 
#   puts "#{user.username}'s Top Tracks"
#   puts "=" * (user.username.length + 13)
#   user.top_tracks.each { |t| puts "(#{t.playcount}) #{t.name}" }
#   
# Which would output something like:
#
#   jnunemaker's Recent Tracks
#   ==========================
#   Everything You Want
#   You're a God
#   Bitter Sweet Symphony [Original Version]
#   Lord I Guess I'll Never Know
#   Country Song
#   Bitter Sweet Symphony (Radio Edit)
# 
# 
#   jnunemaker's Top Tracks
#   =======================
#   (62) Probably Wouldn't Be This Way
#   (55) Not Ready To Make Nice
#   (45) Easy Silence
#   (43) Song 2
#   (40) Everybody Knows
#   (39) Before He Cheats
#   (39) Something's Gotta Give
#   (38) Hips Don't Lie (featuring Wyclef Jean)
#   (37) Unwritten
#   (37) Move Along
#   (37) Dance, Dance
#   (36) We Belong Together
#   (36) Jesus, Take the Wheel
#   (36) Black Horse and the Cherry Tree (radio version)
#   (35) Photograph
#   (35) You're Beautiful
#   (35) Walk Away
#   (34) Stickwitu
module Scrobbler  
  class User < Base
    # attributes needed to initialize
    attr_reader :username
    
    # profile attributes
    attr_accessor :id, :cluster, :url, :realname, :mbox_sha1sum, :registered
    attr_accessor :registered_unixtime, :age, :gender, :country, :playcount, :avatar
    
    # neighbor attributes
    attr_accessor :match
    
    # track fans attributes
    attr_accessor :weight
    
    class << self
      def new_from_libxml(xml)
        data = {}
        xml.children.each do |child|
          data[:name] = child.content if child.name == 'name'
          data[:url] = child.content if child.name == 'url'
          data[:weight] = child.content if child.name == 'weight'
          data[:match] = child.content if child.name == 'match'
          if child.name == 'image'
            data[:image_small] = child.content if child['size'] == 'small'
            data[:image_medium] = child.content if child['size'] == 'medium'
            data[:image_large] = child.content if child['size'] == 'large'
          end
        end
        User.new(data[:name], data)
      end

      def new_from_xml(xml, doc=nil)
        u        = User.new(xml.at(:name).inner_html)
        u.url    = (xml).at(:url).inner_html    if (xml).at(:url)
        u.avatar = (xml).at(:image).inner_html  if (xml).at(:image)
        u.weight = (xml).at(:weight).inner_html if (xml).at(:weight)
        u.match  = (xml).at(:match).inner_html  if (xml).at(:match)
        u
      end
      
      def find(*args)
        options = {:include_profile => false}
        options.merge!(args.pop) if args.last.is_a?(Hash)
        users = args.flatten.inject([]) { |users, u| users << User.new(u, options); users }
        users.length == 1 ? users.pop : users
      end
    end
    
    def initialize(username, input={})
      data = {:include_profile => false}.merge(input)
      raise ArgumentError if username.blank?
      @username = username
      load_profile() if data[:include_profile]
      populate_data(data)
    end
    
    def api_path
      "/#{API_VERSION}/user/#{CGI::escape(username)}"
    end
    
    def image(which=:small)
      which = which.to_s
      raise ArgumentError unless ['small', 'medium', 'large'].include?(which)      
      instance_variable_get("@image_#{which}")
    end
    
    def current_events(format=:ics)
      format = :ics if format.to_s == 'ical'
      raise ArgumentError unless ['ics', 'rss'].include?(format.to_s)
      "#{API_URL.chop}#{api_path}/events.#{format}"
    end
    
    def friends_events(format=:ics)
      format = :ics if format.to_s == 'ical'
      raise ArgumentError unless ['ics', 'rss'].include?(format.to_s)
      "#{API_URL.chop}#{api_path}/friendevents.#{format}"
    end
    
    def recommended_events(format=:ics)
      format = :ics if format.to_s == 'ical'
      raise ArgumentError unless ['ics', 'rss'].include?(format.to_s)
      "#{API_URL.chop}#{api_path}/eventsysrecs.#{format}"
    end
    
    def load_profile
      doc                  = self.class.fetch_and_parse("#{api_path}/profile.xml")
      @id                  = (doc).at(:profile)['id']
      @cluster             = (doc).at(:profile)['cluster']
      @url                 = (doc).at(:url).inner_html
      @realname            = (doc).at(:realname).inner_html
      @mbox_sha1sum        = (doc).at(:mbox_sha1sum).inner_html
      @registered          = (doc).at(:registered).inner_html
      @registered_unixtime = (doc).at(:registered)['unixtime']
      @age                 = (doc).at(:age).inner_html
      @gender              = (doc).at(:gender).inner_html
      @country             = (doc).at(:country).inner_html
      @playcount           = (doc).at(:playcount).inner_html
      @avatar              = (doc).at(:avatar).inner_html
    end
    
    def top_artists(force=false, period='overall')
      get_response('user.gettopartists', :top_artists, 'topartists', 'artist', {'user' => @username, 'period'=>period}, force)
    end
    
    def top_albums(force=false, period='overall')
      get_instance2('user.gettopalbums', :top_albums, :album, {'user'=>@username, 'period'=>period}, force)
    end
    
    def top_tracks(force=false, period='overall')
      get_instance2('user.gettoptracks', :top_tracks, :track, {'user'=>@username, 'period'=>period}, force)
    end
    
    def top_tags(force=false)
      get_instance2('user.gettoptags', :top_tags, :tag, {'user'=>@username}, force)
    end
    
    def friends(force=false, page=1, limit=50)
      get_instance2('user.getfriends', :friends, :user, {'user'=>@username, 'page'=>page.to_s, 'limit'=>limit.to_s}, force)
    end
    
    def neighbours(force=false)
      get_instance2('user.getneighbours', :neighbours, :user, {'user'=>@username}, force)
    end
    
    def recent_tracks(force=false)
      get_instance2('user.getrecenttracks', :recent_tracks, :track, {'user'=>@username}, force)
    end
    
    def recent_banned_tracks(force=false)
      #warn "#{file}:#{lineno}:Warning: Scrobbler::User#recent_banned_tracks is deprecated (not supported by the Last.fm 2.0 API)"
      get_instance(:recentbannedtracks, :recent_banned_tracks, :track, force)
    end
    
    def recent_loved_tracks(force=false)
      #warn "#{file}:#{lineno}:Warning: Scrobbler::User#recent_loved_tracks is deprecated (not supported by the Last.fm 2.0 API)"
      get_instance(:recentlovedtracks, :recent_loved_tracks, :track, force)
    end
    
    def recommendations(force=false)
      #warn "#{file}:#{lineno}:Warning: Scrobbler::User#recommendations is deprecated (not supported by the Last.fm 2.0 API)"
      get_instance(:systemrecs, :recommendations, :artist, force)
    end
    
    def charts(force=false)
      get_instance2('user.getweeklychartlist', :charts, :chart, {'user'=>@username}, force)
    end
    
  end
end
