# lua-github
`lua-github` is a small wrapper around the github API. It's currently primarily focused on user, org and team read-operations but the hope is to extend it to as much of the github api as possible.

## Install
Easiest option is probably to install from luarocks:

`luarocks install github`

Alternately, you can install via the included `Makefile`. You'll probably want to override the `LUA_SHAREDIR` environment variable. You'll also need to make sure you install [my httpclient library](https://github.com/lusis/lua-httpclient). Since github uses SSL, if you're using the `luasocket` driver you'll need `luasec` as well. If you're only using it via ngx-lua/openresty, you shouldn't need `luasec`.

## Requirements
The following versions were tested
- lua 5.2 (the version that shipped with trusty)
- httpclient 0.1.0-6
- openresty 1.7.4.1

## Usage
Below are a few examples of usage both with nginx and luasocket/luasec. Results of most api calls return either
- a lua table of the json (via `cjson.decode`) and nil error
or
- a nil result and an error message

Some api calls return `true`/`false` and any relevant error.

### straight lua

```lua
local inspect = require 'inspect'
local gh = require('github').new()
gh:set_access_token('XXXXXXXX')
-- alternately: local gh = require('github').new({access_token = 'XXXXXXXXX'})
local r, err = gh:get_authenticated_user()
print(err)
-- no access token

gh:set_access_token('XXXXXXXX')
-- alternately: local gh = require('github').new({access_token = 'XXXXXXXXX'})

local r, err = gh:get_authenticated_user()

if err then
  print(err)
else
  inspect(r)
end
-- {
--   avatar_url = "https://avatars.githubusercontent.com/u/228958?v=3",
--   bio = <userdata 1>,
--   blog = "http://about.me/lusis",
--   company = "The Lusis Group",
--   created_at = "2010-03-23T20:28:44Z",
--   email = "lusis.org+github.com@gmail.com",
--   events_url = "https://api.github.com/users/lusis/events{/privacy}",
--   followers = 231,
--   followers_url = "https://api.github.com/users/lusis/followers",
--   following = 97,
--   following_url = "https://api.github.com/users/lusis/following{/other_user}",
--   gists_url = "https://api.github.com/users/lusis/gists{/gist_id}",
--   gravatar_id = "",
--   hireable = false,
--   html_url = "https://github.com/lusis",
--   id = 228958,
--   location = "Roswell, GA.",
--   login = "lusis",
--   name = "John E. Vincent",
--   organizations_url = "https://api.github.com/users/lusis/orgs",
--   public_gists = 231,
--   public_repos = 137,
--   received_events_url = "https://api.github.com/users/lusis/received_events",
--   repos_url = "https://api.github.com/users/lusis/repos",
--   site_admin = false,
--   starred_url = "https://api.github.com/users/lusis/starred{/owner}{/repo}",
--   subscriptions_url = "https://api.github.com/users/lusis/subscriptions",
--   type = "User",
--   updated_at = "2014-12-03T20:56:53Z",
--   url = "https://api.github.com/users/lusis"
-- }

print(r.login)
-- lusis
local r, err = gh:get_authed_user_org_membership('github', 'lusis')
print(r)
-- false
local r, err = gh:get_authed_user_org_membership('logstash', 'lusis')
print(r)
-- true
```

### nginx usage
The nginx usage is largely similar but you'll need to follow [the httpclient instructions](https://github.com/lusis/lua-httpclient#openrestynginx-example) to set up the internal redirect in nginx.
Then you'll use this library specifying the alternate driver:

```lua
ngx.var.access_token = 'XXXXXXX'
local gh = require('github').new({access_token = ngx.var.access_token, httpclient_driver = 'httpclient.ngx_driver'})
local r, err = gh:get_authenticated_user()
if err or r.login ~= 'lusis' then
  ngx.exit(ngx.HTTP_UNAUTHORIZED)
else
  ngx.say("welcome "..r.login)
end
```

### oauth usage
Alternately you can make all calls with oauth credentials but it's up to you to store those somewhere inside nginx each authenticated user. The library provides a few helpers you can use:

- Generate a redirect url for oauth requests: `gh:get_authorize_url(client_id, scope)`
- Process an oauth callback code to generate a usable auth token: `gh:request_token(callback_code, args)`

In the second example, args is a lua table like so:
```lua
args = {
  client_id = 'XXXXXXX',
  client_secret = 'YYYYYYY',
  redirect_uri = 'http://hostname/my_oauth_callback'
}
```

## Authenticated vs Unauthenticated calls
Note that the library can be used out of the box without having a github access token. Most calls provide authenticated vs unauthenticated versions. For example:

- `get_user(username)`
vs
- `get_authenticated_user()`

The first option makes a call to `https://api.github.com/users/<username>` while the second makes a call to `https://api.github.com/user?access_token=XXXXXXX`.
This allows you to use public calls for some operations where the token isn't neccessary.

## Debugging the underlying httpclient
A feature of `httpclient` is the ability to get details about the last request made. The github library exposes the raw httpclient via `gh.hc`. Any functions available to straight httpclient can be used here as well like `res = gh.hc:get('https://httpbin.org/get')`.

With every action in `httpclient` you can always call `get_last_request()` which will return some information about the driver as well as the data passed in to driver to make the request.
For example while writing this library, I ran into some header related bugs with nginx. I was able to debug this information like so:

```lua
local inspect = require 'inspect'
ngx.log(ngx.ERR, inspect(gh.hc:get_last_request().get_headers()))
```

Which is where I realized that my `accept` header wasn't being passed to the github api properly.

## TODO
- tests
- environment variable + bin script for a quick cli client
- more docs
- docker/rocket for quick openresty environment for testing
