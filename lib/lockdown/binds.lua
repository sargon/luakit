-------------------------------------------------------
-- LockDown bindings                                 --
-- (C) 2012 Daniel Ehlers <danielehlers@mindeye.net> --
-------------------------------------------------------

local menu_binds = menu_binds
local lousy   = require "lousy"
local cache   = require "lockdown.cache"
local access  = require "lockdown.access"
local record  = require "lockdown.record"
local add_binds = add_binds
local add_cmds = add_cmds
local new_mode = new_mode
local tostring = tostring
local cmd = lousy.bind.cmd

module "lockdown.binds"

add_cmds({
    -- View all downloads in an interactive menu
    cmd("blocked", function (w)
        w:set_mode("lockdown_tracked_requests")
    end),
})

-- Add additional binds to downloads menu mode.
local key = lousy.bind.key
add_binds("lockdown_tracked_requests", lousy.util.table.join({
    key({}, "w" , function (w)
      local row = w.menu:get()
      if row and row.domain then
        local hostname = w.view.uri
        local domain   = row.domain
        local accessReq = access.evaluate(hostname,domain)
       --lockdown_set_domain_whitelisted(row.domain)
      end
    end),
    key({}, "t", function(w) 
      local row = w.menu:get()
      if row and row.plugin ~= nil then
        --w:toggle_plugins()
      end
      if row and row.script ~= nil then
        --w:toggle_scripts()
      end
      if row and row.path and row.request and row.domain then
        local hostname = w.view.uri
        cache.togglePath(row.domain,row.path)
        local accessRes = access.evaluate(hostname,row.request)
        record.addRequest(w.view,row.request,accessRes)
        w.menu:update()
      end
    end),
    -- Exit menu
    key({},  "q", function (w) w:set_mode() end),

}, menu_binds))
