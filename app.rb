# encoding: utf-8
Encoding.default_internal = "utf-8"
Encoding.default_external = "utf-8"

require "json"
require "time"
require "date"
require "erb"
require "cgi"

require "redis"
require "jellyfish"

# ruby 1.9- compatibility
unless respond_to?(:__dir__, true)
  def __dir__
    File.dirname(__FILE__)
  end
end

$redis = Redis.new(:thread_safe => true)

module Routes
  CHANNEL = '(?<channel>[\w\.]+)'
  DATE    = '(?<date>[\w\-]+)'
  TIME    = '(?<time>[\d\.]+)'
end

module IRC_Log
  class App
    include Jellyfish, Routes

    controller_include Module.new{
      def erb path
        ERB.new(views(path)).result(binding)
      end

      def views path
        @views ||= {}
        @views[path] ||= File.read("#{__dir__}/views/#{path}.erb")
      end

      def user_text text
        autolink(CGI.escape_html(text))
      end

      def autolink text
        text.gsub(%r{https?://\S+\b}, '<a href="\0">\0</a>')
      end
    }

    get %r{^/?$} do
      redirect "/channel/g0v.tw/today"
    end

    get %r{^/?channel/#{CHANNEL}$} do |m|
      redirect "/channel/#{m[:channel]}/today"
    end

    get %r{^/channel/([-.\w]+)/(today|yesterday|[-\d]+)/?(json)?$} do |channel, date, format|
      case date
        when "today"
          @date = Time.now.strftime("%F")
        when "yesterday"
          @date = (Time.now - 86400).strftime("%F")
        else
          # date in "%Y-%m-%d" format (e.g. 2013-01-01)
          @date = m[:date]
      end

      @channel = m[:channel]

      @msgs = $redis.lrange("irclog:channel:##{@channel}:#{@date}", 0, -1)
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

    get "/live/:channel" do |channel|
      @channel = channel
      today = Time.now.strftime("%Y-%m-%d")
      @msgs = $redis.lrange("irclog:channel:##{channel}:#{today}", -25, -1)
      @msgs = @msgs.map {|msg| JSON.parse(msg) }.reverse
      @msgs = @msgs.select {|msg| msg["msg"][/^\[\S*\]\s.*/] }

      erb :live
    end

    get %r{^/?widget/#{CHANNEL}$} do |m|
      @channel = m[:channel]
      today = Time.now.strftime("%Y-%m-%d")
      @msgs = $redis.lrange("irclog:channel:##{@channel}:#{today}", -25, -1)
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
  class App
    include Jellyfish, Routes

    controller_include Module.new{
      def fetch_messages channel, date
        $redis.lrange("irclog:channel:##{channel}:#{date}", -10, -1).
          map{ |msg| ::JSON.parse(msg) }
      end

      def extract_if messages, time
        if not messages.empty? and messages[-1]["time"] > time
          extract(messages, time)
        end
      end

      def extract messages, time
        messages.select{ |msg| msg["time"] > time }.to_json
      end
    }

    get %r{^/?poll/#{CHANNEL}/#{TIME}/updates\.json$} do |m|
      channel, time = m[:channel], m[:time]
      date = Time.at(time.to_f).strftime("%Y-%m-%d")
      msgs = fetch_messages(channel, date)
      json = extract_if(msgs, time)
      next json if json

      # we simply block here because we're in a threaded server anyway
      n = 0
      loop do
        sleep 0.5
        msgs = fetch_messages(channel, date)
        if n <= 120 && json = extract_if(msgs, time)
          break json
        elsif n <= 120
          n += 1
        else
          break extract(msgs, time)
        end
      end
    end
  end
end
