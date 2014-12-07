local lpeg = require 'lpeg'
local P, C, R, S, Cs, Cc, Ct, Cf, Cg, V, Cmt = lpeg.P, lpeg.C, lpeg.R, lpeg.S, lpeg.Cs, lpeg.Cc, lpeg.Ct, lpeg.Cf, lpeg.Cg, lpeg.V, lpeg.Cmt
local lpegmatch, lpegpatterns, replacer = lpeg.match, lpeg.patterns, lpeg.replacer
local inspect = require 'inspect'

local function parse_link_header(str)
  -- This is our placeholder for matches
  local links = links or {}

  -- As we get a table match, we add a new entry to the links table in the format of:
  -- { reltype = "target" }
  local function build_pagination(t1)
    links[t1.rel] = t1.url
    return t1
  end

  -- link headers look like so:
  -- <someurl>; rel="sometype"
  -- multiple links can be joined together with commas:
  -- <someurl1>; rel="foo",<someurl2>; rel="bar"
  --
  local openbracket = P("<")
  local closebracket = P(">")
  local semicolon = P(";")
  local equal = P("=")
  local comma = P(",")
  local quote = P('"')
  local endofstring = P(-1)
  local nothing = Cc("")
  local whitespace = P(" ")^1
  -- target is the url in in between <>
  local target = Cg(((P(1) - closebracket)^-0), "url")
  -- reltype is the value for rel
  local reltype = Cg(((P(1) - quote)^-0), "rel")
  -- Make a capture table of one match
  -- { rel = "next", url = "https://....." }
  local match_one = Ct((whitespace)^0 * openbracket * target * closebracket * semicolon * (whitespace)^0 * "rel=" * quote * reltype * quote * (whitespace)^0 * (comma)^0)
  -- apply function to one match
  local linkwfunc = (match_one / build_pagination)
  -- make a capture table of one or more matches
  local match_any = Ct((linkwfunc)^1)
  -- do the match
  match_links = lpegmatch(match_any, str)
  return links
end

local parsers = {
  parse_link_header = parse_link_header
}

return parsers
