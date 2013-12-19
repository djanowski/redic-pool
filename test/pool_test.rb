require "cutest"

$VERBOSE = 1

module Parsers
  def self.info(reply)
    Hash[reply.lines.grep(/^[^#]/).map { |line| line.chomp.split(":", 2) }]
  end
end

require_relative "../lib/redic/pool"

at_exit do
  if $redis
    Process.kill(:TERM, $redis)
  end

  Process.waitpid
end

$redis = spawn("redis-server --dir /tmp --dbfilename '' --port 9999 --logfile /dev/null")

sleep(0.5)

def teardown(r)
  r.pool.shutdown { |c| c.call("QUIT") }
end

setup do
  Redic::Pool.new("redis://localhost:9999", size: 10)
end

test "Pool" do |r|
  threads = Array.new(100) do
    Thread.new do
      10.times do
        r.call("GET", "foo")
      end
    end
  end

  threads.each(&:join)

  clients = Parsers.info(r.call("INFO", "clients")).fetch("connected_clients")

  assert_equal(clients, "10")

  teardown(r)
end

test "MULTI return value with WATCH" do |r|
  r.call("DEL", "foo")

  r.with do |c|
    c.call("WATCH", "foo", "bar")

    c.queue("MULTI")
    c.queue("SET", "foo", "bar")
    c.queue("EXEC")

    assert_equal(c.commit.last, ["OK"])
  end

  assert_equal(r.call("GET", "foo"), "bar")

  teardown(r)
end

test "Pipelining" do |r|
  r.call("DEL", "foo")

  catch(:out) do
    r.with do |c|
      c.queue("SET", "foo", "bar")
      throw(:out)
    end
  end

  assert_equal nil, r.call("GET", "foo")

  teardown(r)
end

test "Pipelining with nesting" do |r|
  r.call("DEL", "foo")

  r.with do |c1|
    c1.queue("DEL", "foo")

    r.with do |c2|
      c2.queue("SET", "foo", "bar")
    end

    c1.commit
  end

  assert_equal "bar", r.call("GET", "foo")

  teardown(r)
end

test "Pipelining contention" do |r|
  threads = Array.new(100) do
    Thread.new do
      10.times do
        r.with do |c|
          c.call("SET", "foo", "bar")

          r.with do |c|
            c.call("DEL", "foo")
          end
        end
      end
    end
  end

  threads += Array.new(100) do
    Thread.new do
      10.times do
        r.with do |c|
          c.queue("SET", "foo", "bar")
          c.queue("DEL", "foo")
          c.commit
        end
      end
    end
  end

  threads.each(&:join)

  clients = Parsers.info(r.call("INFO", "clients")).fetch("connected_clients")

  assert_equal(clients, "10")
  assert_equal(r.call("GET", "foo"), nil)

  teardown(r)
end
