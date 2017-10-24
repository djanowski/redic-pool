require "connection_pool"
require "redic"

class Redic::Pool
  VERSION = "1.0.1"

  attr :url
  attr :pool

  def initialize(url, options = {})
    @url = url
    @pool = ConnectionPool.new(size: options.fetch(:size, 10)) { Redic.new(url) }
    @buffer = Hash.new { |h, k| h[k] = [] }
  end

  def buffer
    @buffer[Thread.current.object_id]
  end

  def reset
    @buffer.delete(Thread.current.object_id)
  end

  def call(*args)
    @pool.with do |client|
      client.call(*args)
    end
  end

  def queue(*args)
    buffer << args
  end

  def commit
    @pool.with do |client|
      client.buffer.concat(buffer)
      client.commit
    end
  ensure
    reset
  end
end
