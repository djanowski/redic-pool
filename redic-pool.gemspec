require "./lib/redic/pool"

Gem::Specification.new do |s|
  s.name = "redic-pool"
  s.description = "A Redis connection pool using Redic"

  s.version = Redic::Pool::VERSION

  s.homepage = "https://github.com/djanowski/redic-pool"

  s.summary = "A Redis connection pool using Redic."

  s.authors = ["Damian Janowski"]

  s.email = ["jano@dimaion.com"]

  s.license = "Unlicense"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }

  s.add_runtime_dependency 'redic', '~> 1.5', '>= 1.5.0'
  s.add_runtime_dependency 'connection_pool', '~> 2.2', '>= 2.2.0'

  s.add_development_dependency 'rake', '~> 10.4', '>= 10.4.2'
  s.add_development_dependency 'cutest', '~> 1.2', '>= 1.2.2'
  s.add_development_dependency 'ohm', '~> 2.3', '>= 2.3.0'
end
