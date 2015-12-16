require 'rubygems'
require 'bundler/setup'
require 'geocoder'
require_relative 'eliza'

class Chatbot
  def reply_message(received_msg)
    message = create_message( received_msg )

    message['ToUserName']   = received_msg['FromUserName']
    message['FromUserName'] = received_msg['ToUserName']
    message['CreateTime']   = "#{Time.now.to_i}"
    message.delete('MsgId')

    message
  end

  def create_message(received_msg)
    raise NotImplementedError
  end

  def text_message(content)
    {
      'MsgType' => 'text',
      'Content' => content.to_s
    }
  end
end

class ElizaBot < Chatbot
  def create_message(received_msg)
    input    = received_msg['Content'].to_s.downcase.split
    response = Eliza.eliza_rule( input, Rule::ELIZA_RULES )
    text_message( response )
  end
end

class EchoBot < Chatbot
  def create_message(received_msg)
    received_msg.dup
  end
end

class MonitorBot < Chatbot
  def create_message(received_msg)
    type  = received_msg['MsgType'].to_s.downcase
    event = received_msg['Event'  ].to_s.downcase

    message = {}

    case
    when type == 'text' && rand > 0.75
      message = text_message( "Mention my name (@eliza) to talk about anything." )
    when type == 'text'
      # Do nothing
    when type == 'event' && event == 'location' && rand > 0.75
      results = Geocoder.search( "#{ received_msg['Latitude'] }, #{ received_msg['Longitude'] }" )
      message = text_message( "How is the weather in #{results.first.city}?" )
    when type == 'event' && event == 'subscribe'
      message = text_message(
        "Welcome to our official account! I am Eliza. " \
        "Mention my name (@eliza) to talk about anything."
      )
    when type == 'event'
      message = text_message( "WeChat just sent me your #{event} event" )
    else
      message = text_message( "I don't understand your #{type} message yet" )
    end

    message
  end
end