require_relative "prelude"

require "ohm"

class Post < Ohm::Model
  attribute :title

  index :title
end

class Comment < Ohm::Model
  attribute :body
end

setup do
  Ohm.redis = Redic::Pool.new("redis://localhost:9999")
end

test "Pool - basic" do
  threads = Array.new(10) do |i|
    Thread.new(i) do |i|
      10.times do |j|
        Post.create(title: "Foo #{i} #{j}").id
        Comment.create(body: "Bar #{i} #{j}").id
      end
    end
  end

  threads.each(&:join)

  clients = Parsers.info(Ohm.redis.call("INFO", "clients")).fetch("connected_clients")

  assert_equal(clients, "10")

  teardown(Ohm.redis)

  Ohm.redis = Redic::Pool.new("redis://localhost:9999")

  threads = Array.new(10) do |i|
    Thread.new(i) do |i|
      10.times do |j|
        Post.all.to_a
        Comment.all.to_a
      end
    end
  end

  threads.each(&:join)

  clients = Parsers.info(Ohm.redis.call("INFO", "clients")).fetch("connected_clients")

  assert_equal(clients, "10")
end

test "Pool - empty" do
  record = Post.find(title: 'does_not_exist')

  assert_equal(record.first, nil)
  assert_equal(record.to_a, [])

  teardown(Ohm.redis)
end
