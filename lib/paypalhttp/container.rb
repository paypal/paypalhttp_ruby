module PayPalHttp

  # the purpose of this class is to work around OpenStruct's inefficiency.
  # it employs a more dynamic meta programming approach to prevent
  # invalidation of ruby's global method cache.
  # see https://mensfeld.pl/2015/04/ruby-global-method-cache-invalidation-impact-on-a-single-and-multithreaded-applications/
  class Container
    attr_reader :attributes

    def initialize(attributes = {})
      @attributes = attributes
    end

    def respond_to? meth
      @attributes.key?(meth) || attribute_writer?(meth) || super
    end

    def method_missing(meth, *args, &blk)
      if attribute_writer?(meth)
        key = meth.to_s.tr('=', '').to_sym
        @attributes[key] = args.first
      elsif key = attributes_key(meth)
        @attributes[key]
      else
        super
      end
    end

    def []=(key, value)
      @attributes[key] = value
    end

    def [](key)
      @attributes[key]
    end

    protected

      def attribute_writer?(meth)
        meth.to_s.end_with?("=")
      end

      def attributes_key(meth)
        [ meth.to_sym, meth.to_s ].detect { |k| @attributes.key?(k) }
      end
  end
end
