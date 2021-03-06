-------------------------------------------------------
-- LockDown bindings                                 --
-- (C) 2012 Daniel Ehlers <danielehlers@mindeye.net> --
-------------------------------------------------------

local menu_binds = menu_binds
local lousy   = require "lousy"
local cache   = require "lockdown.cache"
local access  = require "lockdown.access"
local record  = require "lockdown.record"
local util    = require "lockdown.util"
local add_binds = add_binds
local add_cmds = add_cmds
local new_mode = new_mode

local buf = lousy.bind.buf
local cmd = lousy.bind.cmd
local key = lousy.bind.key

module "lockdown.binds"

add_cmds({
    -- View all downloads in an interactive menu
    cmd("blocked", function (w)
        w:set_mode("lockdown_tracked_requests")
    end),
})

-- Add additional binds to downloads menu mode.
add_binds("lockdown_tracked_requests", lousy.util.table.join({
    key({}, "t", function(w) 
      local row = w.menu:get()
      if row and row.script then
        w:toggle_scripts(false)
      end
      if row and row.plugin then
        w:toggle_plugins(false)
      end
    end),
    key({}, "w" , function (w)
      local row = w.menu:get()
      if row and row.domain then
        local hostURI  = w.view.uri
        local uri      = util.uriParse(w.view.uri)
        local domain   = row.domain 
        local hostname = util.getHostname(uri) 

        if row.path and row.request then
          local path = row.path
          cache.togglePathWhiteList(hostname,domain,path)
          local accessRes = access.evaluate(hostURI,row.request)
          record.addRequest(w.view,row.request,accessRes)
        else 
          cache.toggleDomainWhiteList(hostname,domain)
        end
      end
      w.menu:update()
    end),
    key({}, "b" , function (w)
      local row = w.menu:get()
      if row and row.domain then
        local hostURI  = w.view.uri
        local uri      = util.uriParse(w.view.uri)
        local domain   = row.domain 
        local hostname = util.getHostname(uri) 

        if row.path and row.request then
          local path = row.path
          cache.togglePathBlackList(hostname,domain,path)
          local accessRes = access.evaluate(hostURI,row.request)
          record.addRequest(w.view,row.request,accessRes)
        else 
          cache.toggleDomainBlackList(hostname,domain)
        end
      end
      w.menu:update()
    end),
    -- Exit menu
    key({},  "q", function (w) w:set_mode() end),

}, menu_binds))


-- normal mode binds
add_binds("normal", {
  buf("^ga$", function (w)  
    w:set_mode("lockdown_tracked_requests") 
  end),
})
