require 'dalli'
require 'active_support/cache/dalli_store'

module RestCore
  class Cache
    def cache_clear env
      return env unless cache(env)
      return env unless cache_for?(env)
  
      cache_store(env, :delete, nil)
    end
  end
end

module Randle
  class Store < ActiveSupport::Cache::DalliStore
    def initialize(addresses, options={}) # avoid ActiveSupport's extract_options!
      addresses = addresses.flatten
      @options = options
      @options[:compress] ||= @options[:compression]
      @raise_errors = !!@options[:raise_errors]
      servers = if addresses.empty?
                  nil # use the default from Dalli::Client
                else
                  addresses
                end
      @data = Dalli::Client.new(servers, @options)
    end

    def [] key
      read key
    end

    def []= key, value
      value ? write(key, value) : delete(key)
    end

    def store key, value, options={}
      value ? write(key, value, options) : delete(key)
    end

    private
    def expanded_key key # avoid ActiveSupport to_param
      return key.cache_key.to_s if key.respond_to?(:cache_key)
      case key
      when Array
        if key.size > 1
          key = key.collect{|element| expanded_key(element)}
        else
          key = key.first
        end
      when Hash
        key = key.sort_by { |k,_| k.to_s }.collect{|k,v| "#{k}=#{v}"}
      end
      key.to_s
    end

    def instrument operation, key, options=nil
      log operation, key, options
      yield
    end

  end
end

MEMCACHED_STORE = Randle::Store.new(CONFIG['memcached_stores'], compress: true)

class ModelInCache
  attr_accessor :id
  def self.key aid
    "#{name}_#{aid}"
  end

  def self.find aid
    MEMCACHED_STORE.read(key(aid))
  end

  def self.find_or_initialize aid
    raise "id must be an Integer or String" unless aid.is_a?(Integer) or aid.is_a?(String)
    find(aid) || new(id: aid)
  end

  def self.create attrs
    new(attrs).save
  end

  def initialize attrs
    (attrs || {}).each do |k, v|
      send("#{k}=", v) if respond_to?(k)
    end
  end

  def save
    MEMCACHED_STORE.write(UserInCache.key(@id), self, expires_in: 21 * 86400)
  end

  def destroy
    MEMCACHED_STORE.delete(UserInCache.key(@id))
  end

  def update_attributes attrs
    initialize attrs; save
  end
end

class UserInCache < ModelInCache
  attr_accessor :etag
end
