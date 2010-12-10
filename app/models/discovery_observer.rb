#require 'mq'
class DiscoveryObserver < ActiveRecord::Observer
  observe Host
  def test
    return nil
    begin
      EM.run {
        conn = AMQP.connect(:host => MQ_SERVER, :port => MQ_PORT, :user => MQ_USER, :pass => MQ_PWD)
        channel = MQ.new(conn)
        channel.queue('mp_queue').publish(Marshal.dump(['mp', '', '13718781273', 'hello, shitou']))
        conn.close
      }
    rescue AMQP::Error
    end
  end
end
