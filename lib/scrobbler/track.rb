# Below is an example of how to get the top fans for a track.
# 
#   track = Scrobbler::Track.new('Carrie Underwood', 'Before He Cheats')
#   puts 'Fans'
#   puts "=" * 4
#   track.fans.each { |u| puts u.username }
#   
# Which would output something like:
# 
#   track = Scrobbler::Track.new('Carrie Underwood', 'Before He Cheats')
#   puts 'Fans'
#   puts "=" * 4
#   track.fans.each { |u| puts "(#{u.weight}) #{u.username}" }
# 
#   Fans
#   ====
#   (69163) PimpinRose
#   (7225) selene204
#   (7000) CelestiaLegends
#   (6817) muehllr
#   (5387) Mudley
#   (5368) ilovejohnny1984
#   (5232) MeganIAD
#   (5132) Veric
#   (5097) aeVnar
#   (3390) kristaaan
#   (3239) kelseaowns
#   (2780) syndication
#   (2735) mkumm
#   (2706) Kimmybeebee
#   (2648) skorpcroze
#   (2549) mistergreg
#   (2449) mlmjcace
#   (2302) tiNEey
#   (2169) ajsbabiegirl
module Scrobbler
  class Track < Base
    # Load Helper modules
    include ImageObjectFuncs
    extend  ImageClassFuncs
    
    attr_accessor :artist, :name, :mbid, :playcount, :rank, :url, :id, :count
    attr_accessor :streamable, :album, :date, :now_playing, :tagcount
    attr_accessor :duration, :listeners
    
    class << self
      def new_from_xml(xml, o = {})
        data = self.data_from_xml(xml, o)
        return nil if data[:name].nil?
        if data[:artist].blank? 
          if data[:creator].blank? 
            data[:artist] = data[:creator];
          else 
            raise Error, "Supplied XML to track has no artist or creator"
          end
        end
        Track.new(data[:artist], data)
      end
      
      def data_from_xml(xml, o = {})
        o = {:include_album_info => true, :include_artist_info => true}.merge(o) 
        data = {}
        xml.children.each do |child|
          data[:name] = child.content if child.name == 'name' || child.name == 'title'
          data[:mbid] = child.content.to_i if child.name == 'mbid'
          data[:id] = child.content.to_i if child.name == 'id'
          data[:duration] = child.content.to_i if child.name == 'duration'
          data[:url] = child.content if child.name == 'url' || child.name == 'identifier'
          data[:date] = Time.parse(child.content) if child.name == 'date'
          data[:listeners] = child.content.to_i if child.name == 'listeners'
          data[:artist] = Artist.new_from_xml(child, o) if (child.name == 'artist' || child.name == 'creator') && o[:include_artist_info]
          data[:album] = Album.new_from_xml(child, o) if child.name == 'album' && o[:include_album_info]
          data[:playcount] = child.content.to_i if child.name == 'playcount'
          data[:tagcount] = child.content.to_i if child.name == 'tagcount'
          maybe_image_node(data, child)
          if child.name == 'streamable'
            if ['1', 'true'].include?(child.content)
              data[:streamable] = true
            else
              data[:streamable] = false
            end
          end
        end
        
        
        data[:rank] = xml['rank'].to_i if xml['rank']
        data[:now_playing] = true if xml['nowplaying'] && xml['nowplaying'] == 'true'
        
        data[:now_playing] = false if data[:now_playing].nil? 
        o.merge(data)
      end
    end
    
    def initialize(input, data={})
      super()
      #check for old style parameter arguments
      if data.class == String 
        data = {:name => data}
      end
      
      if input.class == String && data[:mbid] && data[:mbid] == true
        raise ArgumentError, "MBID is required for an MBID query" if input.blank?
        @mbid = input
        load_album_info() unless !data[:include_info].nil? && data[:include_info] == false 
      else
        raise ArgumentError, "Artist is required" if input.blank?
        raise ArgumentError, "Name is required" if data[:name].blank?
        @artist = Artist.new(input)
        @name = data[:name]
        load_info() if data[:include_info]
      end
    end
    
    def add_tags(tags)
      # This function requires authentication, but SimpleAuth is not yet 2.0
      raise NotImplementedError
    end

    def ban
      # This function requires authentication, but SimpleAuth is not yet 2.0
      raise NotImplementedError
    end
    
    @info_loaded = false
    def load_info
      return nil if @info_loaded
      doc = Base.request('track.getinfo', :artist => @artist.name, :track => @name)
      doc.root.children.each do |child|
        next unless child.name == 'track'
        data = self.class.data_from_xml(child)
        populate_data(data)
        @info_loaded = true
        break
      end
    end

    def top_fans(force=false)
      get_response('track.gettopfans', :fans, 'topfans', 'user', {:artist=>@artist.name, :track=>@name}, force)
    end
    
    def top_tags(force=false)
      get_response('track.gettoptags', :top_tags, 'toptags', 'tag', {:artist=>@artist.name.to_s, :track=>@name}, force)
    end
    
    def ==(otherTrack)
      if otherTrack.is_a?(Scrobbler::Track)
        return ((@name == otherTrack.name) && (@artist == otherTrack.artist))
      end
      false
    end
  end
end
