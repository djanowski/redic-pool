require_relative "prelude"

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

  r.call("WATCH", "foo", "bar")

  r.queue("MULTI")
  r.queue("SET", "foo", "bar")
  r.queue("EXEC")

  assert_equal(r.commit.last, ["OK"])

  assert_equal(r.call("GET", "foo"), "bar")

  teardown(r)
end

test "Pipelining" do |r|
  r.call("DEL", "foo")

  r.queue("SET", "foo", "bar")

  assert_equal nil, r.call("GET", "foo")

  teardown(r)
end

test "Pipelining contention" do |r|
  threads = Array.new(100) do
    Thread.new do
      10.times do
        r.call("SET", "foo", "bar")

        r.call("DEL", "foo")
      end
    end
  end

  threads += Array.new(100) do
    Thread.new do
      10.times do
        r.queue("SET", "foo", "bar")
        r.queue("DEL", "foo")
        r.commit
      end
    end
  end

  threads.each(&:join)

  clients = Parsers.info(r.call("INFO", "clients")).fetch("connected_clients")

  assert_equal(clients, "10")
  assert_equal(r.call("GET", "foo"), nil)

  teardown(r)
end

test "URL" do |r|
  assert_equal("redis://localhost:9999", r.url)
end
