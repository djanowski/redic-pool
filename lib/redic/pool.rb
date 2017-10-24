require "connection_pool"
require "redic"

class Redic::Pool
  VERSION = "1.0.1"

  attr :url
  attr :pool

  def initialize(url = "redis://127.0.0.1:6379", timeout = 10_000_000, **opts)
    opts[:size] = 10 unless opts.key?(:size)

    @url = url
    @pool = ConnectionPool.new(opts) { Redic.new(url, timeout) }

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
      Thread.current[@id].each do |args|
        client.queue(*args)
      end

      result = client.commit

      Thread.current[@id].clear

      result
    end
  end
end
