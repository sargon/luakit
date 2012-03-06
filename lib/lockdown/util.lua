-------------------------------------------------------
-- Utility function for lockdown                     --
-- (C) 2012 Daniel Ehlers <danielehlers@mindeye.net> --
-------------------------------------------------------
local assert = assert 
local string = string
local tonumber = tonumber

local lousy = require "lousy"

module("lockdown.util")


function boolToInt(bool) 
  return bool and 1 or 0
end

function intToBool(int) 
  return tonumber(int) ~= 0 
end

function uriParse(uri)
  return assert(lousy.uri.parse(uri), "malformed uri")
end

function getHostname(uri)
  return string.lower(uri.host)
end

function getPath(uri)
  return uri.path
end

local function toMatchString(str)
  return string.gsub(str,"[%^%%%$%(%)%%%.%[%]%*%+%-%?]","%%%1") .. "$";
end

function isSubDomain(hostname,domain)
  matchPattern = toMatchString(domain)
  return nil ~=  string.match(hostname,matchPattern)
end

function isSLDSubDomain(host,domain)
  sld       = string.match(domain,"([^%.]+%.[^%.]+)$")
  sldOfHost = string.match(host,"([^%.]+%.[^%.]+)$")
  return sldOfHost == sld
end

function boolToColor(bool)
  if bool then 
    return "green"
  else 
    return "red"
  end
end
