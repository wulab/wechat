require 'rubygems'
require 'bundler/setup'
require 'digest/sha1'
require 'securerandom'
require 'sinatra'
require_relative 'eliza'
require_relative 'text_message'
require_relative 'unknown_message'

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

  def request_body
    request.body.rewind
    request.body.read
  end

  def reply(message, content)
    TextMessage.new(
      sender:    message.recipient,
      recipient: message.sender,
      sent_at:   Time.now.utc,
      content:   content
    )
  end
end

before do
  error 404 unless check_signature
  logger.debug request_body
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
  pass unless request_body.include?('<MsgType><![CDATA[text]]></MsgType>')
  incoming = TextMessage.parse(request_body)
  response = Eliza.eliza_rule(incoming.content.downcase.split, Rule::ELIZA_RULES)
  outgoing = reply(incoming, response)
  body outgoing.to_xml
end

post '/' do
  pass unless request_body.include?('<MsgType><![CDATA[event]]></MsgType>')
  incoming = UnknownMessage.parse(request_body)
  response = "WeChat just sent me your #{incoming.event} event"
  outgoing = reply(incoming, response)
  body outgoing.to_xml
end

post '/' do
  incoming = UnknownMessage.parse(request_body)
  response = "I don't understand your #{incoming.type} message"
  outgoing = reply(incoming, response)
  body outgoing.to_xml
end

error NotImplementedError do
  body ''
end