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
  r.pool.shutdown { |c| c.call!("QUIT") }
end
