require "connection_pool"
require "redic"

class Redic::Pool
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
  alias_method :call!, :call

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
