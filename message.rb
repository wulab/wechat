require 'rubygems'
require 'bundler/setup'
require 'oga'

class Message
  attr_reader :id, :sender, :recipient, :sent_at

  def self.parse(document)
    raise NotImplementedError
  end

  def self.text_at_xpath(xpath, root)
    node = root.at_xpath(xpath)
    node && node.text
  end

  def initialize
    raise NotImplementedError
  end

  def to_xml
    raise NotImplementedError
  end
end

def assert(expression, message = 'Test failed')
  @assert_count ||= 0
  @assert_count  += 1
  raise message unless expression
end

def test
  raise NotImplementedError
end

if $0 == __FILE__
  test
end