require! <[fs]>

flist = fs.readdir-sync \raw
for f in flist
  lines = fs.read-file-sync "raw/#f" .to-string!split \\n
  date = /([^.]+)\.txt/.exec f
  if not date => continue
  date = date.1
  state = 0
  for line in lines
    if state == 0 =>
      ret = /<li id="\d+">/.exec line
      if ret => state = 1
      continue
    else if state == 1 =>
      ret = /<a class="time"[^>]+>([^<]+)<\/a>/.exec line
      if ret =>
        time = ret.1
        state = 2
      continue
    else if state == 2 =>
      ret = /<a class="nick"[^>]+>(.+)<\/a>/.exec line
      if ret =>
        nick = ret.1
        state = 3
      continue
    else if state == 3 =>
      ret = /<span class="msg wordwrap">(.+)<\/span>/.exec line
      if ret =>
        quote = ret.1
        state = 0
        console.log date, time, nick, quote
      continue

