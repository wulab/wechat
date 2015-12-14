require_relative 'message'

class TextMessage < Message
  attr_reader :content

  def self.parse(xml)
    document  = Oga.parse_xml( xml )

    id        = text_at_xpath('xml/MsgId'       , document)
    sender    = text_at_xpath('xml/FromUserName', document)
    recipient = text_at_xpath('xml/ToUserName'  , document)
    sent_at   = text_at_xpath('xml/CreateTime'  , document)
    content   = text_at_xpath('xml/Content'     , document)

    new(
      id:        id,
      sender:    sender,
      recipient: recipient,
      sent_at:   Time.at( sent_at.to_i ).utc,
      content:   content
    )
  end

  def initialize(id: nil, sender:, recipient:, sent_at:, content:)
    @id        = id
    @sender    = sender
    @recipient = recipient
    @sent_at   = sent_at
    @content   = content
  end

  def to_xml
    <<-XML
<xml>
  <ToUserName><![CDATA[#{recipient}]]></ToUserName>
  <FromUserName><![CDATA[#{sender}]]></FromUserName>
  <CreateTime>#{sent_at.to_i}</CreateTime>
  <MsgType><![CDATA[text]]></MsgType>
  <Content><![CDATA[#{content}]]></Content>#{
    "\n  <MsgId>#{id}</MsgId>" unless id.nil?
  }
</xml>
    XML
  end
end

def test
  incoming = TextMessage.parse(<<-XML)
<xml>
  <ToUserName><![CDATA[gh_d82667417b44]]></ToUserName>
  <FromUserName><![CDATA[oHQYpv0JfYXtQ1aJOUKJd4mnxMYs]]></FromUserName>
  <CreateTime>1449644190</CreateTime>
  <MsgType><![CDATA[text]]></MsgType>
  <Content><![CDATA[hello]]></Content>
  <MsgId>6226174387287320382</MsgId>
</xml>
  XML
  incoming = TextMessage.parse( incoming.to_xml )

  assert incoming.is_a?(Message)
  assert incoming.id           == '6226174387287320382'
  assert incoming.sender       == 'oHQYpv0JfYXtQ1aJOUKJd4mnxMYs'
  assert incoming.recipient    == 'gh_d82667417b44'
  assert incoming.sent_at.to_s == '2015-12-09 06:56:30 UTC'
  assert incoming.content      == 'hello'

  outgoing = TextMessage.new(
    sender:    incoming.recipient,
    recipient: incoming.sender,
    sent_at:   incoming.sent_at + 60,
    content:   'hi'
  )

  assert outgoing.is_a?(Message)
  assert outgoing.sender       == 'gh_d82667417b44'
  assert outgoing.recipient    == 'oHQYpv0JfYXtQ1aJOUKJd4mnxMYs'
  assert outgoing.sent_at.to_s == '2015-12-09 06:57:30 UTC'
  assert outgoing.content      == 'hi'

  assert outgoing.id.nil?
  assert !outgoing.to_xml.include?('<MsgId>')

  puts "#{@assert_count} tests passed"
end

if $0 == __FILE__
  test
end