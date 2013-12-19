require "connection_pool"
require "redic"

class Redic::Pool
  VERSION = "0.1.0"

  attr :pool

  def initialize(url, options = {})
    @pool = ConnectionPool.new(size: options.fetch(:size, 10)) { Redic.new(url) }
  end

  def call(*args)
    @pool.with do |client|
      client.call(*args)
    end
  end

  def with(&block)
    @pool.with(&block)
  end
end
