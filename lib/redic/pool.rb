require "connection_pool"
require "redic"

class Redic::Pool
  VERSION = "1.0.1"

  attr :url
  attr :pool

  def initialize(url, options = {})
    @url = url
    @pool = ConnectionPool.new(size: options.fetch(:size, 10)) { Redic.new(url) }

    @id = "redic-pool-#{object_id}"
  end

  def call(*args)
    @pool.with do |client|
      client.call(*args)
    end
  end

  def queue(*args)
    Thread.current[@id] || (Thread.current[@id] = [])
    Thread.current[@id] << args
  end

  def commit
    @pool.with do |client|

      break unless Thread.current[@id]

      Thread.current[@id].each do |args|
        client.queue(*args)
      end

      result = client.commit

      Thread.current[@id].clear

      result
    end
  end
end
