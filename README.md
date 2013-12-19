Redic::Pool
===========

A Redis connection pool using [Redic](https://github.com/amakawa/redic).

Usage
-----

    require "redic/pool"

    $redis = Redic::Pool.new("redis://localhost:6379", size: 10)

    Array.new(100) do
      Thread.new do
        $redis.call("GET", "foo")
      end
    end.each(&:join)

    $redis.call("INFO", "clients")[/connected_clients:(\d+)/, 1]
    # => "10"
