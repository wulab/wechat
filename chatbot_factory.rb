require_relative 'chatbot'

class ChatbotFactory
  def create_chatbot(received_msg)
    command = received_msg['Content'].to_s
    chatbot = nil

    case command
    when /@Eliza/i
      chatbot = ElizaBot.new
    when /@Echo/i
      chatbot = EchoBot.new
    else
      chatbot = MonitorBot.new
    end

    chatbot
  end
end