%w{cgi rubygems hpricot active_support}.each { |x| require x }

$: << File.expand_path(File.dirname(__FILE__))

require 'scrobbler/base'
require 'scrobbler/version'


require 'scrobbler/album'
require 'scrobbler/artist'
require 'scrobbler/chart'
require 'scrobbler/event'
require 'scrobbler/geo'
require 'scrobbler/user'
require 'scrobbler/tag'
require 'scrobbler/track'

require 'scrobbler/simpleauth'
require 'scrobbler/scrobble'
require 'scrobbler/playing'

require 'scrobbler/rest'

require 'scrobbler/search'
