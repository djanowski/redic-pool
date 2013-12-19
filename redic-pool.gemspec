require "./lib/redic/pool"

Gem::Specification.new do |s|
  s.name = "redic-pool"

  s.version = Redic::Pool::VERSION

  s.homepage = "https://github.com/djanowski/redic-pool"

  s.summary = "A Redis connection pool using Redic."

  s.authors = ["Damian Janowski"]

  s.email = ["jano@dimaion.com"]

  s.license = "Unlicense"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }

  s.add_dependency("connection_pool")
  s.add_dependency("redic")

  s.add_development_dependency("cutest")
end
