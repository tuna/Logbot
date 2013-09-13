# Process.setrlimit(Process::RLIMIT_NOFILE, 4096, 65536)
require File.join(File.dirname(__FILE__), "app")

use Rack::ContentLength
use Rack::ContentType
use Class.new(Rack::CommonLogger){ # For logging hijacked requests
      def call env
        began_at = Time.now
        status, header, body = @app.call(env)
        header = Rack::Utils::HeaderHash.new(header)

        if env['rack.hijack_io'] || header['rack.hijack']
          env['REQUEST_METHOD'].sub!(/$/, ' HIJACKED')
          log(env, status, header, began_at) # hijacked
        else
          body = Rack::BodyProxy.new(body) {
            log(env, status, header, began_at) }
        end

        [status, header, body]
      end
    }, $stderr

run Rack::URLMap.new \
  "/" => IRC_Log::App.new,
  "/comet" => Comet::App.new,
  "/assets" => Rack::Directory.new("public")
