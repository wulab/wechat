require 'rubygems'
require 'bundler/setup'
require 'active_support/core_ext/hash'
require 'digest/sha1'
require 'securerandom'
require 'sinatra'
require_relative 'chatbot_factory'

helpers do
  def request_body
    request.body.rewind
    request.body.read
  end

  def received_message
    document = Hash.from_xml( request_body )
    document['xml']
  end

  def valid_message?(message)
    message.key?( 'MsgType' )
  end

  def to_xml(hash)
    hash.to_xml(
      dasherize:     false,
      indent:        2,
      root:          'xml',
      skip_instruct: true,
      skip_types:    true
    )
  end
end

before do
  logger.info('request') { "\n#{ request_body }" } if request.post?
end

after do
  logger.info('response') { "\n#{ body[0] }" }
end

configure :production do
  set :token, ENV['TOKEN'] || SecureRandom.urlsafe_base64
  puts "Token set to #{settings.token}"

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
  end
end

# http://admin.wechat.com/wiki/index.php?title=Getting_Started
get '/' do
  body params[:echostr]
end

# http://admin.wechat.com/wiki/index.php?title=Common_Messages
post '/' do
  factory = ChatbotFactory.new
  chatbot = factory.create_chatbot( received_message )
  message = chatbot.reply_message( received_message )

  if valid_message?(message)
    body to_xml(message)
  else
    body ''
  end
end

error NotImplementedError do
  body ''
end