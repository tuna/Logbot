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

    get %r{^/?channel/#{CHANNEL}/#{DATE}$} do |m|
      case m[:date]
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
        msg
      }

      erb :channel
    end

    get %r{^/?widget/#{CHANNEL}$} do |m|
      @channel = m[:channel]
      today = Time.now.strftime("%Y-%m-%d")
      @msgs = $redis.lrange("irclog:channel:##{@channel}:#{today}", -25, -1)
      @msgs = @msgs.map {|msg| JSON.parse(msg) }.reverse

      erb :widget
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
