require! <[fs]>

if process.argv.length < 3 =>
  console.log "usage: lsc search.ls [keyword]"
  process.exit 0

keyword = process.argv.2

lines = fs.read-file-sync \all-msg .toString!split \\n
hash = {}
for line in lines
  reg = new RegExp "\\S+ \\S+ (\\S+) (.*#keyword.*)"
  ret = reg.exec line
  if not ret => continue
  if not ret.1 in hash => hash[ret.1] = []
  hash.[][ret.1] .push ret.2

for nick of hash =>
  console.log nick, hash[nick]
