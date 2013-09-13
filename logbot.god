God.watch do |w|
  w.name = "Logbot agent"
  w.start = "ruby /home/rails/logbot/logbot.rb"
  w.keepalive
end

God.watch do |w|
  w.name = "Logbot web"
  w.start = "rainbows -N -p 15000 -c /home/rails/logbot/rainbows.rb /home/rails/logbot/config.ru"
  w.keepalive
end
