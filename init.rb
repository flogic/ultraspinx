unless ActiveRecord::Base.respond_to? :inherited_with_search_wrapper
  ActiveRecord::Base.send(:include, SearchWrapper)

  class ActiveRecord::Base
    def self.inherited_with_search_wrapper(subclass)
      self.inherited_without_search_wrapper(subclass)
      subclass.send(:include, SearchWrapper) unless subclass < SearchWrapper
    end

    class << self
      alias_method_chain :inherited, :search_wrapper
      alias_method_chain :is_indexed, :search_wrapper
    end
  end
end
