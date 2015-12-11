require 'rubygems'
require 'bundler/setup'
require 'digest/sha1'
require 'securerandom'
require 'sinatra'
require_relative 'eliza'
require_relative 'message'

configure do
  set :token, ENV['TOKEN'] || SecureRandom.urlsafe_base64
  puts "Token set to #{settings.token}"
end

helpers do
  # http://admin.wechat.com/wiki/index.php?title=Message_Authentication
  def check_signature
    nonce     = params[:nonce]
    signature = params[:signature]
    timestamp = params[:timestamp]

    tmp_arr = [settings.token, timestamp, nonce].compact.sort
    tmp_str = tmp_arr.join
    tmp_str = Digest::SHA1.hexdigest(tmp_str)

    tmp_str == signature
  end
end

before do
  error 404 unless check_signature
  logger.debug request.body.read
end

after do
  logger.debug body
end

# http://admin.wechat.com/wiki/index.php?title=Getting_Started
get '/' do
  body params[:echostr]
end

# http://admin.wechat.com/wiki/index.php?title=Common_Messages
post '/' do
  request.body.rewind
  incoming = Message.parse(request.body.read)

  outgoing = Message.new(
    sender:    incoming.recipient,
    recipient: incoming.sender,
    sent_at:   Time.now.utc,
    content:   Eliza.eliza_rule(incoming.content.downcase.split, Rule::ELIZA_RULES)
  )

  body outgoing.to_xml
end

error NotImplementedError do
  body ''
end