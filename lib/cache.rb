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
