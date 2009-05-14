require 'pathname'

# See http://avdi.org/devblog/2009/03/02/smart-requires-in-ruby/
# Also http://opensoul.org/2008/1/9/ruby-s-require-doesn-t-expand-paths
require File.join File.expand_path(File.dirname(__FILE__)), "..", File.basename(__FILE__,".rb").sub(/_.*/,'')
require File.join File.expand_path(File.dirname(__FILE__)), (File.basename(__FILE__,".rb") + "_data")
require 'rubygems'
gem 'testy', '~> 0.5.0'
require 'testy'

Testy.testing "queries on 1 collection" do
  context 'AIDS' do
    test 'looking for "high"' do |result|
      result.check :results, :expect => TestData.aids.queries.high, :actual => CollectionReader.fetch("high", "aids")
    end
  end
end