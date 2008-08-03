# Recache
# This library wraps functionality for the EVE-Online API provided by Reve with a transparent caching layer.
# Author:: James Harrison (Ix Forres) http://www.talkunafraid.co.uk/
# Copyright:: GNU LGPL 3.0

unless Reve
  raise ReveError, "The Reve plugin was not found. Is it installed?"
end
RECACHE_LOGGER = Logger.new("#{RAILS_ROOT}/log/recache_#{RAILS_ENV}.log")
module Recache
  class API
    @@last_call_updated = true
    @@http_user_agent = "Recached 1.1/Reve"
    @@last_hash = nil
    @@cached_until = nil
    cattr_accessor :last_call_updated, :http_user_agent, :last_hash, :cached_until
    # As with Reve's initialize function- parameters are all the same.
    # Loads up a new instance of Reve and sets user/key/character IDs
    # Expects:
    # * API User ID ( Integer | String ) - API User ID
    # * API Key ( String ) - API Key
    # * Character ID ( Integer ) - CharacterID to use. Can be declared here or optionally anywhere later on.
    # * Gatecamper App Key ( String ) - Application key if you are using Gatecamper. In this case, UserID may be negated and API Key is used for the user's key.
    # Please note that Gatecamper support requires you to register a Gatecamper account at http://gatecamper.org and add your application.
    # Your copy of Reve may not support Gatecamper, remember to update or to apply the patch available at http://gatecamper.org/developers/libraries
    def initialize(user_id='', key='', character_id='', gatecamper_app_key = false) 
      @user_id      = user_id.to_s
      @key          = key.to_s
      @character_id = character_id.to_s
      @gatecamper_app_key = gatecamper_app_key
      if @gatecamper_app_key
        @api = Reve::API.new(@user_id, @key, @character_id, @gatecamper_app_key)
      else
        @api = Reve::API.new(@user_id, @key, @character_id)
      end
      @api.http_user_agent = @@http_user_agent
    end
    
    # Default handler for any incoming methods that Recache doesn't have explicitly defined.
    # This handles all the transparency by silently diverting requests to the cache instead of Reve and so on.
    # Expects:
    # * Method ( String ) - The method being called
    # * Args ( Array ) - Optional arguments passed to Reve
    def method_missing(method, *args)
      arg_hash = args.first
      arg_hash = {} unless arg_hash
      # Don't try handling cache if we're looking for the alliancelist...
      if method.to_s.include?('alliance')
        return @api.send( method, arg_hash )
      end
      cache, @@last_call_updated = get_cache_if_available( method, arg_hash )
      if cache
        if cache.cached_until.to_time < Time.now
          cache, @@last_call_updated = update_cache( method, arg_hash )
        end
      else
        cache, @@last_call_updated = update_cache( method, arg_hash )
      end
      # Flip/flop between returning the Reve data class or our serialised Reve data class.
      if cache.class == RecacheStore
        return cache.data
      else
        return cache
      end
    end
    # Returns the next time an update from the EVE API can occour, or Time.now if no cache exists for the given hash.
    # Expects:
    # * Method ( String ) - The method being called
    # * Args ( Array ) - Optional arguments passed to Reve
    def next_update?(method, opts={})
      options = {:just_hash => true}.merge( opts )
      hash = @api.send( method, options )
      return RecacheStore.find_by_request_hash( hash.to_s, :order => 'cached_until DESC' ).cached_until
    end
    
  private
  
    # Gets value from cache if available.
    # Returns a RecacheStore and hash or nil if no cache is available
    # Expects:
    # * Method ( String ) - The method being called
    # * Args ( Array ) - Optional arguments passed to Reve
    def get_cache_if_available(method, opts={})
      if opts == nil then opts = {} end
      options = {:just_hash => true}.merge( opts )
      hash = @api.send( method, options )
      return RecacheStore.find(:first, :conditions => ['cached_until > NOW() AND request_hash = ?',hash.to_s], :order => 'id DESC' ), false
    end
    
    # Updates a given cache method/arg hash from Reve
    # Returns data directly from Reve and stores a serialized copy.
    # Expects:
    # * Method ( String ) - The method being called
    # * Args ( Array ) -  Optional arguments passed to Reve
    def update_cache(method, args)
      if args == nil then args = {} end
      revedat = @api.send( method, args )
      # First we clear out any old caches - delete instead of destroy, if you have anything depending on caches you're insane
      RecacheStore.delete_all( ['request_hash = ?', @api.last_hash] )
      RecacheStore.create( :request_hash => @api.last_hash, :data => revedat, :cached_until => @api.cached_until )
      return revedat, true
    end
    
  end
  
  # Reve-related errors- includes Reve not existing.
  class ReveError < RuntimeError; end
end