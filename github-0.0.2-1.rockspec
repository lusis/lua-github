package = "github"
version = "0.0.2-1"
source = {
  url = "git://github.com/lusis/lua-github",
  tag = "0.0.2-1"
}
description = {
  summary = "Github API library",
  detailed = [[
    A library largely focused on handling user, organization and team related reads from github. Has helpers for oauth"
    ]],
    homepage = "https://github.com/lusis/lua-github",
    license = "Apache"
}
dependencies = {
  "httpclient ~> 0.1.0-7",
  "lpeg ~> 0.12-1"
}
build = {
  type = "builtin",
  modules = {
    ['github'] = 'src/github.lua',
    ['github.parsers'] = 'src/github/parsers.lua'
  }
}
