-------------------------------------------------------
-- LockDown resource request logging                 --
-- (C) 2012 Daniel Ehlers <danielehlers@mindeye.net> --
-------------------------------------------------------

local util   = require "lockdown.util"

module "lockdown.record"

requestRecord = {}

function start(view)
  requestRecord[view] = {}
end

function addRequest(view,requestURI,accessResult)
  local uri = util.uriParse(requestURI)
  if requestRecord[view][util.getHostname(uri)] == nil then
    requestRecord[view][util.getHostname(uri)] = {}
  end
  requestRecord[view][util.getHostname(uri)][uri.path] = accessResult
end

function getRequest(view,requestURI)
  local uri = util.uriParse(requestURI)
  return requestRecord[view][util.getHostname(uri)][uri.path]
end
