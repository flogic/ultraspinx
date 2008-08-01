module SearchWrapper
  def self.included(klass)
    klass.extend ClassMethods

    class << klass
      # provide a class-level attribute accessor for holding on to Ultrasphinx's is_indexed arguments for later review
      attr_accessor :indexed_data
    end
  end

  module ClassMethods
    # provide a simple Model.search() wrapper around the Ultrasphinx 3-step search process
    def search(args = {})
      raise ArgumentError, ":query argument is required" unless args[:query]
      begin
        @search_handle = Ultrasphinx::Search.new({:class_names => self.name}.merge(args))
        if block_given?
          @search_handle.run(false)
          return yield(@search_handle)
        else
          @search_handle.run
          return @search_handle.results
        end
      rescue Exception => e
        logger.error("*** Ultrasphinx lookup error***:  #{e.message}\n#{e.backtrace.join("\n")}") if self.respond_to?(:logger)
        []
      end
    end

    # hook the is_indexed() method from Ultrasphinx so we can inspect how the arguments were passed later
    def is_indexed_with_search_wrapper(*args)
      self.indexed_data = args
      is_indexed_without_search_wrapper(*args)
    end
  end
end
