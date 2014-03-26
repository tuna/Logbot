# Process.setrlimit(Process::RLIMIT_NOFILE, 4096, 65536)
require File.join(File.dirname(__FILE__), "app")

use Rack::CommonLogger
use Rack::ContentLength
use Rack::ContentType, 'text/html; charset=utf-8'

run Rack::URLMap.new \
  "/" => IRC_Log::App.new,
  "/comet" => Comet::App.new,
  "/assets" => Rack::Directory.new("public")
