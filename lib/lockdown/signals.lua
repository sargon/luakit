-------------------------------------------------------
-- LockDown Signal bindings and Object extensions    --
-- (C) 2012 Daniel Ehlers <danielehlers@mindeye.net> --
-------------------------------------------------------

local access = require "lockdown.access"
local db     = require "lockdown.database"
local util   = require "lockdown.util"
local record = require "lockdown.record"
local webview = webview
local table   = table
local string = string
local tostring = tostring
local pairs = pairs
local lousy   = require "lousy"
local warn    = warn 

module "lockdown.signals"

webview.init_funcs.lockdown_init = function (view,window)

  -- save information about the current state
  local current = { hostname  = "about:blank"
                  , status  = "_not_changed"
                  , blocked = {}
                  }
  
  -- track status changes
  view:add_signal("load-status", function (v,status)
    current.status = status
    if v.uri == nil or status == nil then return end

    -- NoScript: script and plugin handling
    if status == "committed" and v.uri ~= "about:blank" then
      local enable_scripts = access.config.defaultAllowScript
      local enable_plugins = access.config.defaultAllowPlugins
      local row            = db.nsMatchDomain(current.hostname)
      if row then
        enable_scripts = row.enable_scripts
        enable_plugins = row.enable_plugins
      end
      v.enable_scripts = enable_scripts
      v.enable_plugins = enable_plugins
    end
  end)

  -- decide on resource requests
  view:add_signal("resource-request-starting",function(v,requestURI)

    -- Nothing to do here
    if requestURI == "about:blank" then return end

    local uri = util.uriParse(requestURI)

    -- start of a new request row
    if current.status == "provisional" then
      current.hostname = util.getHostname(uri)
      current.blocked = {}
      -- start of a new log for this view
      record.start(v)
    end

    if v.uri == nil then 
      --lockdown_register_final_decision(v,uri,true)
      return 
    end

    if uri ~= nil then
      -- lockdown_new_request(v,uri)
      
      local accessReq = access.evaluate(current.hostname,requestURI)

      -- draw some blocking informations into a menu
      if not accessReq.result then
        table.insert(current.blocked,requestURI)
        warn("Blocked %s",requestURI)
        window:notify(string.format("Blocked #%i request",#current.blocked))
      end
      record.addRequest(v,requestURI,accessReq)
      return accessReq.result 
    end
  end)
end
