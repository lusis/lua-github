-- @module github
-- Copyright (C) 2014 John E. Vincent (lusis)

local cjson = require 'cjson'

local _M = {}
local m = {}

_M.VERSION = "0.0.1"

local defaults = {
  api_url        = "https://api.github.com",
  oauth_url      = "https://github.com/login/oauth",
  authorize_base_url  = "https://github.com/login/oauth/authorize",
  access_base_url     = "https://github.com/login/oauth/access_token"
}


function m.new(params)
  local self = {}
  local args = params or {}
  self.access_token = nil
  if not args.httpclient_driver then
    self.hc = require('httpclient').new()
  else
    self.hc = require('httpclient').new(args.httpclient_driver)
  end
  if args.access_token then
    self.access_token = args.access_token
  end
  self.user_agent = args.user_agent or "lua-github ".._M.VERSION
  setmetatable(self, {__index = _M})
  return self
end

function _M:set_access_token(token)
  self.access_token = token
end

function _M:get_access_token()
  return self.access_token
end

function _M:unauthed_request(path, raw)
  if not path then
    return nil, "no path specified"
  end
  local url = defaults.api_url..path
  local res = self.hc:get(url,{headers = {accept = "application/json", ["content-type"] = "application/json", ["user-agent"] = self.user_agent}})
  if raw then
    return res, nil
  else
    if res.err then
      return nil, res.err
    else
      return cjson.decode(res.body), nil
    end
  end
end

function _M:authed_request(path, raw)
  if not path then
    return nil, "no path specified"
  end
  local token = self:get_access_token()
  if not token then
    return nil, "no access token"
  end
  local url = defaults.api_url..path.."?access_token="..token
  local res = self.hc:get(url,{headers = {accept = "application/json", ["content-type"] = "application/json", ["user-agent"] = self.user_agent}})
  if raw then
    return res, nil
  else
    if res.err then
      return nil, res.err
    else
      return cjson.decode(res.body), nil
    end
  end
end

-- returns a url that can be used for oauth redirection
function _M:get_authorize_url(client_id, scope)
  if not client_id or not scope then
    return nil, "missing a require param: client_id or scope"
  else
    return defaults.authorize_base_url.."?client_id="..client_id.."&scope="..scope, nil
  end
end

-- makes a request to github for an access token
-- based on an oauth callback
function _M:request_token(callback_code, args)
  if not callback_code then
    return nil, "this requires a callback code from github"
  end
  if not args.client_id or not args.client_secret or not args.redirect_uri then
    return nil, "missing one of the required params: client_id, client_secret or callback url"
  end
  local params = {
    access_token_url = defaults.access_base_url,
    client_id = args.client_id,
    client_secret = args.client_secret,
    code = callback_code,
    redirect_uri = args.redirect_uri
  }

  local opts = {
    headers = { accept = "application/json" },
    params = params,
  }

  local res = self.hc:post(defaults.access_base_url, "", opts)
  if res.err then
    return nil, res.err
  else
    local b = cjson.decode(res.body)
    return b.access_token, nil
  end
end

-- returns details for the requested user
function _M:get_user(username)
  if not username then return nil, "must specificy username" end
  return self:unauthed_request("/users/"..username)
end

-- returns details for the authenticated user
function _M:get_authenticated_user()
  return self:authed_request("/user")
end

-- returns the followers for the requested user
function _M:get_user_followers(username)
  if not username then return nil, "must specify username" end
  return self:unauthed_request("/users/"..username.."/followers")
end

-- returns the followers for the authenticated user
function _M:get_authenticated_user_followers()
  return self:authed_request("/user/followers")
end

-- returns the teams for the authenticated user
function _M:get_authenticated_user_teams()
  return self:authed_request("/user/teams")
end

-- returns the users followed by the requested user
function _M:get_user_following(username)
  if not username then return nil, "must specify username" end
  return self:unauthed_request("/users/"..username.."/following")
end

-- returns the users followed by the authenticated user
function _M:get_authenticated_user_following()
  return self:authed_request("/user/following")
end

-- returns the verified public keys for the requested user
function _M:get_user_pubkeys(username)
  if not username then return nil, "must specify username" end
  return self:unauthed_request("/users/"..username.."/keys")
end

-- returns the keys for the authenticated user
function _M:get_authenticated_user_pubkeys(username)
  return self:authed_request("/user/keys")
end

-- gets a single key for the authenticated user
function _M:get_authenticated_user_key(key_id)
  if not key_id then return nil, "must specify key id" end
  return self:authed_request("/user/keys/"..key_id)
end

function _M:get_org(org_name)
  if not org_name then return nil, "must specify org name" end
  res, err = self:unauthed_request("/orgs/"..org_name, true)
  if res.code ~= 200 then
    return nil, res.err
  else
    return cjson.decode(res.body), nil
  end
end

function _M:get_authed_org(org_name)
  if not org_name then return nil, "must specify org name" end
  res, err = self:authed_request("/orgs/"..org_name, true)
  if res.code ~= 200 then
    return nil, res.err
  else
    return cjson.decode(res.body), nil
  end
end

-- gets an organization's public members
function _M:get_org_members(org_name)
  if not org_name then return nil, "must specify org name" end
  return self:unauthed_request("/orgs/"..org_name.."/members")
end

-- returns org members as visible to the authenticated user
function _M:get_authed_org_members(org_name)
  if not org_name then return nil, "must specify org name" end
  return self:authed_request("/orgs/"..org_name.."/members")
end

-- check if a user is publicly a member of an organization
function _M:get_user_org_membership(org_name, username)
  if not org_name then return nil, "must specify org name" end
  if not username then return nil, "must specify username" end
  local res,_ = self:unauthed_request("/orgs/"..org_name.."/public_members/"..username, true)
  if res.code == 404 then return false, nil end
  if res.code == 204 then return true, nil end
  return nil, res.err
end

-- check if a user is publicly or privately a member of an organization
function _M:get_authed_user_org_membership(org_name, username)
  if not org_name then return nil, "must specify org name" end
  if not username then return nil, "must specify username" end
  local res,_ = self:authed_request("/orgs/"..org_name.."/members/"..string.lower(username), true)
  if res.code == 404 then return false, nil end
  if res.code == 204 then return true, nil end
  return nil, res.err
end

-- returns teams for given org (authed request only)
-- From the github api page:
-- All actions against teams require at a minimum an authenticated user who is a member of the Owners team in the :org being managed.
-- Additionally, OAuth users require the “read:org” scope.
function _M:get_org_teams(org_name)
  if not org_name then return nil, "must specify org name" end
  local res, err = self:authed_request("/orgs/"..org_name.."/teams", true)
  if res.code == 403 then
    return nil, res.err
  else
    return cjson.decode(res.body), nil
  end
end

-- helper: is user in org team (uses current user's token)
function _M:current_user_in_org_team(team_name, org_name)
  if not team_name then return nil, "must specify team name" end
  if not org_name then return nil, "must specify org name" end
  local match = false
  local user_teams, err = self:get_authenticated_user_teams()
  if not user_teams then
    return false, err
  else
    for _, team in pairs(user_teams) do
      if string.lower(team.organization.login) == string.lower(org_name) then
        if string.lower(team.slug) == string.lower(team_name) then
          match = true
          break
        else
          match = false
        end
      end
    end
  end
  return match, nil
end

return m
