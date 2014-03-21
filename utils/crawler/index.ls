require! <[fs request]>

now = new Date!get-time!
idx = 0
first = true
move-on = ->
  cur = new Date ( now - 86400000 * idx )
  idx := idx + 1
  year = cur.get-year! + 1900
  month = cur.get-month! + 1
  month = (if month < 10 => "0" else "" ) + month
  day = cur.get-date!
  day = (if day < 10 => "0" else "" ) + day
  return [year, month, day]

download = ->
  while true
    [year,month,day] = move-on!
    if year==2013 and month==\06 and day==\01 => return
    file = "raw/#year-#month-#day.txt"
    if fs.exists-sync(file) and fs.stat-sync(file)size < 1000 => fs.unlink-sync file
    if not fs.exists-sync(file) => break
    else if first =>
      first := false
      break
  url = "http://logbot.g0v.tw/channel/g0v.tw/#year-#month-#day"
  request url: url, (e,v,b) ->
    console.log file
    fs.write-file-sync file, b
    stats = fs.stat-sync file
    if stats.size < 1000 => 
      fs.unlink-sync file
      idx := idx - 1
    setTimeout download, 100

if not fs.exists-sync \raw/ => fs.mkdir \raw

download!
