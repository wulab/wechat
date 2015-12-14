require_relative 'message'

class UnknownMessage < Message
  attr_reader :type

  def self.parse(xml)
    document  = Oga.parse_xml( xml )

    id        = text_at_xpath('xml/MsgId'       , document)
    type      = text_at_xpath('xml/MsgType'     , document)
    sender    = text_at_xpath('xml/FromUserName', document)
    recipient = text_at_xpath('xml/ToUserName'  , document)
    sent_at   = text_at_xpath('xml/CreateTime'  , document)

    new(
      id:        id,
      sender:    sender,
      recipient: recipient,
      sent_at:   Time.at( sent_at.to_i ).utc,
      type:      type
    )
  end

  def initialize(id: nil, sender:, recipient:, sent_at:, type:)
    @id        = id
    @sender    = sender
    @recipient = recipient
    @sent_at   = sent_at
    @type      = type
  end

  def to_xml
    <<-XML
<xml>
  <ToUserName><![CDATA[#{recipient}]]></ToUserName>
  <FromUserName><![CDATA[#{sender}]]></FromUserName>
  <CreateTime>#{sent_at.to_i}</CreateTime>
  <MsgType><![CDATA[#{type}]]></MsgType>#{
    "\n  <MsgId>#{id}</MsgId>" unless id.nil?
  }
</xml>
    XML
  end
end

def test
  incoming = UnknownMessage.parse(<<-XML)
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
  incoming = UnknownMessage.parse( incoming.to_xml )

  assert incoming.is_a?(Message)
  assert incoming.id           == '6226174387287320382'
  assert incoming.type         == 'voice'
  assert incoming.sender       == 'oHQYpv0JfYXtQ1aJOUKJd4mnxMYs'
  assert incoming.recipient    == 'gh_d82667417b44'
  assert incoming.sent_at.to_s == '2015-12-09 06:56:30 UTC'

  puts "#{@assert_count} tests passed"
end

if $0 == __FILE__
  test
end