require_relative 'message'

class UnknownMessage < Message
  attr_reader :type, :event

  def self.parse(xml)
    document  = Oga.parse_xml( xml )

    id        = text_at_xpath('xml/MsgId'       , document)
    type      = text_at_xpath('xml/MsgType'     , document)
    event     = text_at_xpath('xml/Event'       , document)
    sender    = text_at_xpath('xml/FromUserName', document)
    recipient = text_at_xpath('xml/ToUserName'  , document)
    sent_at   = text_at_xpath('xml/CreateTime'  , document)

    new(
      id:        id,
      sender:    sender,
      recipient: recipient,
      sent_at:   Time.at( sent_at.to_i ).utc,
      type:      type,
      event:     event
    )
  end

  def initialize(id: nil, sender:, recipient:, sent_at:, type:, event: nil)
    @id        = id
    @sender    = sender
    @recipient = recipient
    @sent_at   = sent_at
    @type      = type
    @event     = event
  end

  def to_xml
    <<-XML
<xml>
  <ToUserName><![CDATA[#{recipient}]]></ToUserName>
  <FromUserName><![CDATA[#{sender}]]></FromUserName>
  <CreateTime>#{sent_at.to_i}</CreateTime>
  <MsgType><![CDATA[#{type}]]></MsgType>#{
    "\n  <MsgId>#{id}</MsgId>" unless id.nil?
  }#{
    "\n  <Event>#{event}</Event>" unless event.nil?
  }
</xml>
    XML
  end
end

def test
  message = UnknownMessage.parse(<<-XML)
<xml>
  <ToUserName><![CDATA[gh_d82667417b44]]></ToUserName>
  <FromUserName><![CDATA[oHQYpv0JfYXtQ1aJOUKJd4mnxMYs]]></FromUserName>
  <CreateTime>1449644190</CreateTime>
  <MsgType><![CDATA[voice]]></MsgType>
  <MediaId><![CDATA[media_id]]></MediaId>
  <Format><![CDATA[Format]]></Format>
  <Recognition><![CDATA[WeChat Team]]></Recognition>
  <MsgId>6226174387287320382</MsgId>
</xml>
  XML
  message = UnknownMessage.parse( message.to_xml )

  assert message.is_a?(Message)
  assert message.id           == '6226174387287320382'
  assert message.type         == 'voice'
  assert message.sender       == 'oHQYpv0JfYXtQ1aJOUKJd4mnxMYs'
  assert message.recipient    == 'gh_d82667417b44'
  assert message.sent_at.to_s == '2015-12-09 06:56:30 UTC'

  assert message.event.nil?
  assert !message.to_xml.include?('<Event>')

  event = UnknownMessage.parse(<<-XML)
<xml>
  <ToUserName><![CDATA[gh_d82667417b44]]></ToUserName>
  <FromUserName><![CDATA[oHQYpv0JfYXtQ1aJOUKJd4mnxMYs]]></FromUserName>
  <CreateTime>1449644190</CreateTime>
  <MsgType><![CDATA[event]]></MsgType>
  <Event><![CDATA[view]]></Event>
  <EventKey><![CDATA[www.qq.com]]></EventKey>
</xml>
  XML
  event = UnknownMessage.parse( event.to_xml )

  assert event.is_a?(Message)
  assert event.type         == 'event'
  assert event.event        == 'view'
  assert event.sender       == 'oHQYpv0JfYXtQ1aJOUKJd4mnxMYs'
  assert event.recipient    == 'gh_d82667417b44'
  assert event.sent_at.to_s == '2015-12-09 06:56:30 UTC'

  assert event.id.nil?
  assert !event.to_xml.include?('<MsgId>')

  puts "#{@assert_count} tests passed"
end

if $0 == __FILE__
  test
end