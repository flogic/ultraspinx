require File.dirname(__FILE__) + '/spec_helper'
require 'search_wrapper'
require 'activerecord'

# we should be able to run the specs even if Ultrasphinx is not installed
unless defined? Ultrasphinx
  class Ultrasphinx
    class Search
    end
  end
end

# a simple non-ActiveRecord::Base class for testing
class Foo
  include SearchWrapper
  def self.is_indexed(*args)
  end
end

describe SearchWrapper, "when included into a class" do
  before :each do
    @class = Foo
  end

  it 'should provide a search method to the class' do
    @class.should respond_to(:search)
  end

  describe 'search()' do
    before(:each) do
      @search = stub('Ultrasphinx::Search instance', :run => true, :results => [])
      Ultrasphinx::Search.stubs(:new).returns(@search)
    end

    it 'should accept a hash of arguments' do
      lambda { @class.search(:query => 'bar') }.should_not raise_error(ArgumentError) 
    end

    it 'should require a query' do
      lambda { @class.search(:foo => 'bar') }.should raise_error(ArgumentError) 
    end

    it 'should get a search instance from Ultrasphinx::Search.new' do
      Ultrasphinx::Search.expects(:new).returns(@search)
      @class.search(:query => 'frobnitz')
    end

    it 'should provide the specified query to UltraSearch::Search.new' do
      Ultrasphinx::Search.expects(:new).with(has_entry(:query => 'frobnitz')).returns(@search)
      @class.search(:query => 'frobnitz')
    end

    it 'should pass additional arguments to UltraSearch::Search.new' do
      Ultrasphinx::Search.expects(:new).with(has_entries(:query => 'frobnitz', :bar => 'baz')).returns(@search)
      @class.search(:query => 'frobnitz', :bar => 'baz')
    end

    it 'should specify the model class as the class argument to UltraSearch::Search.new' do
      Ultrasphinx::Search.expects(:new).with(has_entries(:query => 'frobnitz', :class_names => 'Foo')).returns(@search)
      @class.search(:query => 'frobnitz')
    end

    it 'should allow overriding the class_names argument' do
      Ultrasphinx::Search.expects(:new).with(has_entries(:query => 'frobnitz', :class_names => ['Foo', 'Bar'])).returns(@search)
      @class.search(:query => 'frobnitz', :class_names => ['Foo', 'Bar'])
    end

    describe "use custom result reification when given a block" do
      it "should take a block and call it" do
        block_called = mock(:inner)
        @class.search(:query => 'frobnitz') do |search|
          block_called.inner
        end
      end
      
      it "should run search() with false as argument" do
        @search.expects(:run).with(false)
        Ultrasphinx::Search.expects(:new).with(has_entry(:query => 'frobnitz')).returns(@search)
        @class.search(:query => 'frobnitz') do |search|
        end
      end
      
      it "should invoke the block with the search-object" do
        block_test = mock('block_test')
        block_test.expects(:inner).with(@search)
        @class.search(:query => 'frobnitz') do |inner_search|
          block_test.inner(inner_search)
        end
      end
      
      it "should return the result of the block as return value for search" do
        @class.search(:query => 'frobnitz') do |inner_search|
          [:inner_result]
        end.should == [:inner_result]
      end
    end

    it 'should run the search query' do
      @search.expects(:run)
      @class.search(:query => 'frobnitz')
    end

    it 'should request Ultrasphinx search results' do
      @search.expects(:results)
      @class.search(:query => 'frobnitz')
    end

    it 'should return the Ultrasphinx search results' do
      @search.stubs(:results).returns(results = stub('search results'))
      @class.search(:query => 'frobnitz').should == results
    end
    
    describe 'exception handling' do
      describe 'if Ultrasphinx::Search.new throws an exception' do
        before :each do
          Ultrasphinx::Search.stubs(:new).raises(Exception)
          @mock_logger = stub('logger', :error => true)
        end
        
        it 'should not raise an exception' do
          lambda { @class.search(:query => 'frobnitz') }.should_not raise_error
        end
        
        it 'should return an empty list of results' do
          @class.search(:query => 'frobnitz').should == []
        end
        
        describe 'if no logger is available' do
          it 'should not attempt to log the exception' do
            Foo.stubs(:respond_to?).with(:logger).returns(false)
            Foo.expects(:logger).never
            @class.search(:query => 'frobnitz').should == []
          end          
        end
        
        describe 'if logger is available' do
          it 'should log the exception' do
            @mock_logger = stub('logger', :error => true)
            Foo.stubs(:logger).returns(@mock_logger)
            @mock_logger.expects(:error)
            @class.search(:query => 'frobnitz').should == []
          end          
        end
      end
      
      describe 'if Ultrasphinx::Search#run throws an exception' do
        before :each do
          @search = stub('search handle')
          @search.stubs(:run).raises(Exception)
          Ultrasphinx::Search.stubs(:new).returns(@search)
        end
        
        it 'should not raise an exception' do
          lambda { @class.search(:query => 'frobnitz') }.should_not raise_error
        end
        
        it 'should return an empty list of results' do
          @class.search(:query => 'frobnitz').should == []
        end
        
        describe 'if no logger is available' do
          it 'should not attempt to log the exception' do
            Foo.stubs(:respond_to?).with(:logger).returns(false)
            Foo.expects(:logger).never
            @class.search(:query => 'frobnitz').should == []
          end          
        end
        
        describe 'if logger is available' do
          it 'should log the exception' do
            @mock_logger = stub('logger', :error => true)
            Foo.stubs(:logger).returns(@mock_logger)
            @mock_logger.expects(:error)
            @class.search(:query => 'frobnitz').should == []
          end          
        end
      end
      
      describe 'if Ultrasphinx::Search#results throws an exception' do
        before :each do
          @search = stub('search handle')
          @search.stubs(:results).raises(Exception)
          Ultrasphinx::Search.stubs(:new).returns(@search)
        end
        
        it 'should not raise an exception' do
          lambda { @class.search(:query => 'frobnitz') }.should_not raise_error
        end
        
        it 'should return an empty list of results' do
          @class.search(:query => 'frobnitz').should == []
        end
        
        describe 'if no logger is available' do
          it 'should not attempt to log the exception' do
            Foo.stubs(:respond_to?).with(:logger).returns(false)
            Foo.expects(:logger).never
            @class.search(:query => 'frobnitz').should == []
          end          
        end
        
        describe 'if logger is available' do
          it 'should log the exception' do
            @mock_logger = stub('logger', :error => true)
            Foo.stubs(:logger).returns(@mock_logger)
            @mock_logger.expects(:error)
            @class.search(:query => 'frobnitz').should == []
          end          
        end
      end
    end
  end

  describe 'is_indexed_with_search_wrapper' do
    before :each do
      @class.stubs(:is_indexed_without_search_wrapper)
    end

    it 'should accept arguments' do
      lambda { @class.is_indexed_with_search_wrapper({}) }.should_not raise_error(ArgumentError)
    end

    it 'should not require arguments' do
      lambda { @class.is_indexed_with_search_wrapper }.should_not raise_error(ArgumentError)
    end

    it 'should store arguments in the model' do
      @class.expects(:indexed_data=)
      @class.is_indexed_with_search_wrapper
    end

    it 'should call is_indexed_without_search_wrapper' do
      @class.expects(:is_indexed_without_search_wrapper)
      @class.is_indexed_with_search_wrapper
    end

    it 'should provide original arguments to is_indexed_without_search_wrapper' do
      @class.expects(:is_indexed_without_search_wrapper).with(:foo, { :bar => 'baz'})
      @class.is_indexed_with_search_wrapper(:foo, { :bar => 'baz' })
    end
  end

  describe 'indexed_data' do
    it 'should accept no arguments' do
      lambda { @class.indexed_data('foo') }.should raise_error(ArgumentError)
    end

    it 'should return is_indexed arguments stored in the model' do
      @class.stubs(:is_indexed_without_search_wrapper)
      @class.is_indexed_with_search_wrapper(:foo, { :bar => 'baz' })
      @class.indexed_data.should == [ :foo, { :bar => 'baz' } ]
    end
  end

  describe 'indexed_data=' do
    it 'should make data available to indexed_data() (i.e., is an accessor)' do
      @class.indexed_data = 'foo'
      @class.indexed_data.should == 'foo'
    end
  end
end

class ActiveRecord::Base
  def self.columns(*args)
    []
  end
end

class ActiveRecord::Base
  def self.is_indexed(*args) end
end

class Bar < ActiveRecord::Base
end

describe SearchWrapper, "in a Rails application" do
  it 'should not alter ActiveRecord::Base' do	
    ActiveRecord::Base.methods.should_not include("search")
  end

  it 'should not alter ActiveRecord::Base subclasses' do
    Bar.should_not respond_to(:search)
  end

  describe 'when the plugin is initialized' do
    before :all do
      require File.dirname(__FILE__) + '/../init'
    end
   
    it 'should add search to ActiveRecord::Base' do
      ActiveRecord::Base.methods.should include("search")
    end
  
    it 'should add search to any ActiveRecord::Base subclass' do
      Bar.should respond_to(:search)
    end

    it 'should install is_indexed_with_search_wrapper as is_indexed in the model class' do
      Bar.expects(:is_indexed_without_search_wrapper)
      Bar.is_indexed()
    end
  end
end
