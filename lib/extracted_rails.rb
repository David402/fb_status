module ActiveSupport
  module Cache
    # Entry that is put into caches. It supports expiration time on entries and can compress values
    # to save space in the cache.
    class Entry
      attr_reader :created_at, :expires_in

      DEFAULT_COMPRESS_LIMIT = 16 * 1024 # bytes

      class << self
        # Create an entry with internal attributes set. This method is intended to be
        # used by implementations that store cache entries in a native format instead
        # of as serialized Ruby objects.
        def create(raw_value, created_at, options = {})
          entry = new(nil)
          entry.instance_variable_set(:@value, raw_value)
          entry.instance_variable_set(:@created_at, created_at.to_f)
          entry.instance_variable_set(:@compressed, options[:compressed])
          entry.instance_variable_set(:@expires_in, options[:expires_in])
          entry
        end
      end

      # Create a new cache entry for the specified value. Options supported are
      # +:compress+, +:compress_threshold+, and +:expires_in+.
      def initialize(value, options = {})
        @compressed = false
        @expires_in = options[:expires_in]
        @expires_in = @expires_in.to_f if @expires_in
        @created_at = Time.now.to_f
        if value.nil?
          @value = nil
        else
          @value = Marshal.dump(value)
          if should_compress?(@value, options)
            @value = Zlib::Deflate.deflate(@value)
            @compressed = true
          end
        end
      end

      # Get the raw value. This value may be serialized and compressed.
      def raw_value
        @value
      end

      # Get the value stored in the cache.
      def value
        # If the original value was exactly false @value is still true because
        # it is marshalled and eventually compressed. Both operations yield
        # strings.
        if @value
          # In rails 3.1 and earlier values in entries did not marshaled without
          # options[:compress] and if it's Numeric.
          # But after commit a263f377978fc07515b42808ebc1f7894fafaa3a
          # all values in entries are marshalled. And after that code below expects
          # that all values in entries will be marshaled (and will be strings). 
          # So here we need a check for old ones.
          begin
            Marshal.load(compressed? ? Zlib::Inflate.inflate(@value) : @value)
          rescue TypeError
            compressed? ? Zlib::Inflate.inflate(@value) : @value
          end
        end
      end

      def compressed?
        @compressed
      end

      # Check if the entry is expired. The +expires_in+ parameter can override the
      # value set when the entry was created.
      def expired?
        @expires_in && @created_at + @expires_in <= Time.now.to_f
      end

      # Set a new time when the entry will expire.
      def expires_at=(time)
        if time
          @expires_in = time.to_f - @created_at
        else
          @expires_in = nil
        end
      end

      # Seconds since the epoch when the entry will expire.
      def expires_at
        @expires_in ? @created_at + @expires_in : nil
      end

      # Returns the size of the cached value. This could be less than value.size
      # if the data is compressed.
      def size
        if @value.nil?
          0
        else
          @value.bytesize
        end
      end

      private
      def should_compress?(serialized_value, options)
        if options[:compress]
          compress_threshold = options[:compress_threshold] || DEFAULT_COMPRESS_LIMIT
          return true if serialized_value.size >= compress_threshold
        end
        false
      end
    end # class ActiveSupport::Cache::Entry
  end
end

class Object
  # Invokes the method identified by the symbol +method+, passing it any arguments
  # and/or the block specified, just like the regular Ruby <tt>Object#send</tt> does.
  #
  # *Unlike* that method however, a +NoMethodError+ exception will *not* be raised
  # and +nil+ will be returned instead, if the receiving object is a +nil+ object or NilClass.
  #
  # If try is called without a method to call, it will yield any given block with the object.
  #
  # Please also note that +try+ is defined on +Object+, therefore it won't work with
  # subclasses of +BasicObject+. For example, using try with +SimpleDelegator+ will
  # delegate +try+ to target instead of calling it on delegator itself.
  #
  # ==== Examples
  #
  # Without +try+
  #   @person && @person.name
  # or
  #   @person ? @person.name : nil
  #
  # With +try+
  #   @person.try(:name)
  #
  # +try+ also accepts arguments and/or a block, for the method it is trying
  #   Person.try(:find, 1)
  #   @people.try(:collect) {|p| p.name}
  #
  # Without a method argument try will yield to the block unless the receiver is nil.
  #   @person.try { |p| "#{p.first_name} #{p.last_name}" }
  #--
  # +try+ behaves like +Object#send+, unless called on +NilClass+.
  def try(*a, &b)
    if a.empty? && block_given?
      yield self
    else
      __send__(*a, &b)
    end
  end
end

class NilClass
  # Calling +try+ on +nil+ always returns +nil+.
  # It becomes specially helpful when navigating through associations that may return +nil+.
  #
  # === Examples
  #
  #   nil.try(:name) # => nil
  #
  # Without +try+
  #   @person && !@person.children.blank? && @person.children.first.name
  #
  # With +try+
  #   @person.try(:children).try(:first).try(:name)
  def try(*args)
    nil
  end
end
