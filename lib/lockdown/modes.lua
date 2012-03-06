-------------------------------------------------------
-- LockDown command modes                            --
-- (C) 2012 Daniel Ehlers <danielehlers@mindeye.net> --
-------------------------------------------------------

local record = require "lockdown.record"
local access = require "lockdown.access"
local util = require "lockdown.util"
local cache = require "lockdown.cache"
local db = require "lockdown.database"
local pairs = pairs
local string = string
local table   = table
local tostring = tostring
local new_mode = new_mode

local capi = 
  { timer   = timer 
  }
module "lockdown.modes"

new_mode("lockdown_tracked_requests", {
    enter = function (wv)
        local current = wv.tabs:current()
        
        local uri      = util.uriParse(wv.view.uri)
        local hostname = util.getHostname(uri)

        local view     = wv.view

        -- Script and Plugin settings
        local enable_scripts = access.config.defaultAllowScript
        local enable_plugins = access.config.defaultAllowPlugins
        local nsrow  = db.nsMatchDomain(domain)
        if nsrow then
          enable_scripts = nsrow.enable_scripts
          enable_plugins = nsrow.enable_plugins
        end

        -- Build plugin/script entries
        local rows = {{string.format("<span foreground=\"%s\">Plugins %sabled</span>",util.boolToColor(enable_plugins),enable_plugins and "En" or "Dis"), plugin = enable_plugins}
                     ,{string.format("<span foreground=\"%s\">Scripts %sabled</span>",util.boolToColor(enable_scripts),enable_scripts and "En" or "Dis"), script = enable_scripts}
                     ,{ ":: domain","reason",title = true }}

        -- Build domain/hosts + paths list
        for domain,paths in pairs(record.requestRecord[view]) do
            local isDomain = cache.getDomain(domain)
            table.insert(rows, { string.format("<span foreground=\"%s\">%s</span>",util.boolToColor(isDomain ~= nil and isDomain.value),domain)
                               , ""  
                               , domain = domain
                               } 
                        )
            for path,accessReq in pairs(paths) do
              local function pathCol()
                local accessReq = record.getRequest(view,accessReq.request)
                return string.format(" <span foreground=\"%s\">%s</span>"
                                    ,util.boolToColor(accessReq.result)
                                    ,path
                                    )
              end
              table.insert(rows, {pathCol
                               , "" 
                               , domain  = domain, path = path
                               , request = accessReq.request
                               , result  = accessReq.result
                               })
            end
        end
        wv.menu:build(rows)
        wv:notify("Use j/k to move, t toggle, w whitelist.", false)

        -- Update menu every second
        local update_timer = capi.timer{interval=1000}
        update_timer:add_signal("timeout", function ()
            wv.menu:update()
        end)
        wv.requested_uris_menu_state = { update_timer = update_timer }
        update_timer:start()
    end,

    leave = function (wv)
        local ds = wv.requested_uris_menu_state
        if ds and ds.update_timer.started then
            ds.update_timer:stop()
        end
        wv.menu:hide()
    end,
})
