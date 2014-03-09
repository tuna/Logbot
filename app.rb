# encoding: utf-8
Encoding.default_internal = "utf-8"
Encoding.default_external = "utf-8"

require "json"
require "time"
require "date"
require "sinatra/base"
require "sinatra/async"
require "redis"
require "compass"
require "eventmachine"

$redis = Redis.new(:thread_safe => true)

module IRC_Log
  class App < Sinatra::Base
    configure do
      set :protection, :except => :frame_options
    end

    get "/" do
      redirect "/channel/g0v.tw/today"
    end

    get "/channel/:channel" do |channel|
      redirect "/channel/#{channel}/today"
    end

    get %r{/channel/([-.\w]+)/(today|yesterday|[-\d]+)/?(json)?} do |channel, date, format|
      case date
        when "today"
          @date = Time.now.strftime("%F")
        when "yesterday"
          @date = (Time.now - 86400).strftime("%F")
        else
          # date in "%Y-%m-%d" format (e.g. 2013-01-01)
          @date = date
      end

      @channel = channel

      @msgs = $redis.lrange("irclog:channel:##{channel}:#{@date}", 0, -1)
      @msgs = @msgs.map {|msg|
        msg = JSON.parse(msg)
        if msg["msg"] =~ /^\u0001ACTION (.*)\u0001$/
          msg["msg"].gsub!(/^\u0001ACTION (.*)\u0001$/, "<span class=\"nick\">#{msg["nick"]}</span>&nbsp;\\1")
          msg["nick"] = "*"
        end
        if format == 'json'
          msg["time"] = Time.at(msg["time"].to_f).strftime("%F %T")
        end
        msg
      }

      if format == 'json'
        content_type :json
        @msgs.to_json
      else
        erb :channel
      end
    end

    get "/channel/:channel/:date/:line" do |channel, date, line|
      case date
        when "today"
          @date = Time.now.strftime("%F")
        when "yesterday"
          @date = (Time.now - 86400).strftime("%F")
        else
          # date in "%Y-%m-%d" format (e.g. 2013-01-01)
          @date = date
      end

      @channel = channel

      @line = line.to_i

      msgs = $redis.lrange("irclog:channel:##{@channel}:#{@date}", 0, -1)
      if 0 > @line or @line >= msgs.length
        halt(404)
      end
      msg = JSON.parse(msgs[@line])
      @nick = msg["nick"]
      @msg = msg["msg"]
      @time = msg["time"].to_f

      @url = CGI.escape(request.url)

      erb :quote
    end

    get "/widget/:channel" do |channel|
      @channel = channel
      today = Time.now.strftime("%Y-%m-%d")
      @msgs = $redis.lrange("irclog:channel:##{channel}:#{today}", -25, -1)
      @msgs = @msgs.map {|msg| JSON.parse(msg) }.reverse

      erb :widget
    end

    get "/oembed.?:type?" do |type|
      p params[:url]
      match = /http:\/\/.+\/channel\/(.+)\/(.+)\/(.+)/.match(params[:url])

      @channel = match[1]

      date = match[2]
      case date
        when "today"
          @date = Time.now.strftime("%F")
        when "yesterday"
          @date = (Time.now - 86400).strftime("%F")
        else
          # date in "%Y-%m-%d" format (e.g. 2013-01-01)
          @date = date
      end

      line = match[3].to_i
      msgs = $redis.lrange("irclog:channel:##{@channel}:#{@date}", 0, -1)
      if 0 > line or line >= msgs.length
        halt(404)
      end
      msg = JSON.parse(msgs[line])

      @nick = msg["nick"]
      @msg = msg["msg"]

      case type
        when "xml"
          content_type :xml
          erb :oembed
        else
          content_type :json
          {
            :version       => "1.0",
            :type          => "link",
            :title         => "Logbot | ##{@channel} | #{@nick}> #{@msg}",
            :author_name   => @nick,
            :providor_name => "Logbot",
            :providor_url  => request.base_url
          }.to_json
        end
    end
  end
end


module Comet
  class App < Sinatra::Base
    register Sinatra::Async

    get %r{/poll/(.*)/([\d\.]+)/updates.json} do |channel, time|
      date = Time.at(time.to_f).strftime("%Y-%m-%d")
      msgs = $redis.lrange("irclog:channel:##{channel}:#{date}", -10, -1).map{|msg| ::JSON.parse(msg) }
      if not msgs.empty? and msgs[-1]["time"] > time
        return msgs.select{|msg| msg["time"] > time }.to_json
      end

      EventMachine.run do
        n, timer = 0, EventMachine::PeriodicTimer.new(0.5) do
          msgs = $redis.lrange("irclog:channel:##{channel}:#{date}", -10, -1).map{|msg| ::JSON.parse(msg) }
          if not msgs.empty? and msgs[-1]["time"] > time or n > 120
            timer.cancel
            return msgs.select{|msg| msg["time"] > time }.to_json
          end
          n += 1
        end
      end
    end
  end
end
