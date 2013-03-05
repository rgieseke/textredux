local header = [[<!DOCTYPE html>
<html lang="en">
  <head>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8">
    <meta charset="utf-8">
    <title>Textredux</title>
    <link href="site.css" rel="stylesheet">
    <link href='http://fonts.googleapis.com/css?family=Bowlby+One+SC' rel='stylesheet' type='text/css'>
  </head>

  <body>
    <span id="forkongithub"><a href="https://github.com/rgieseke/textredux">Fork me on GitHub</a></span>
    <div class="container">
      <div class="header">
        <span class="title">Textredux</span>
      </div>
      <div class="nav">
        <ul>
          <li><a href="index.html">Main</a></li>
          <li><a href="index.html#Installation">Installation</a></li>
          <li><a href="index.html#Usage">Usage</a></li>
          <li><a href="index.html#Code">Code</a></li>
          <li><a href="index.html#Contribute">Contribute</a></li>
          <li><a href="index.html#Changelog">Changelog</a></li>
          <li><a href="tour.html">Visual Tour</a></li>
        </ul>
      </div>
      <div class="main">]]

local footer = [[
      </div>
      <div class="footer">
        <a href="https://github.com/rgieseke/textredux">Textredux on GitHub</a>
      </div>
    </div>
  </body>
</html>]]

sources = {'index', 'tour'}

for i=1, #sources do
  source = sources[i]
  print(source)
  local f = io.popen('markdown '..source ..'.md', 'r')
  local content = f:read("*a")
  f:close()

  content = content:gsub('<h2>(.-)</h2>', '<h2 id="%1"><a href="#%1">%1</a></h2>')
  local f = io.open(source..'.html', 'w')
  f:write(header)
  f:write(content)
  f:write(footer)
  f:close()
end
