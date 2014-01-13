require "connection_pool"
require "redic"

class Redic::Pool
  VERSION = "1.0.0"

  attr :url
  attr :pool

  def initialize(url, options = {})
    @url  = url
    @pool = ConnectionPool.new(size: options.fetch(:size, cores || 8)) { Redic.new(url) }
    @id   = "redic-pool-#{object_id}"
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

      client.commit
    end
  end
  
  def cores
    case RbConfig::CONFIG['host_os'][/^[A-Za-z]+/]
    when 'darwin'
      Integer(`/usr/sbin/sysctl hw.ncpu`[/\d+/])
    when 'linux'
      if File.exists?("/sys/devices/system/cpu/present")
        File.read("/sys/devices/system/cpu/present").split('-').last.to_i+1
      else
        Dir["/sys/devices/system/cpu/cpu*"].select { |n| n=~/cpu\d+/ }.count
      end
    when 'mingw', 'mswin'
      Integer(ENV["NUMBER_OF_PROCESSORS"][/\d+/])
    when 'freebsd'
      Integer(`sysctl hw.ncpu`[/\d+/])
    else
      nil
    end
  end
end
