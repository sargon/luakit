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
        local function arePluginsEnabled()
          local enable_plugins = access.config.defaultAllowPlugins
          local nsrow  = db.nsMatchDomain(hostname)

          if nsrow then
            enable_plugins = nsrow.enable_plugins
          end
          return string.format( "<span foreground=\"%s\">Plugins %sabled</span>"
                              , util.boolToColor(enable_plugins)
                              , enable_plugins and "En" or "Dis"
                              )
        end

        local function areScriptsEnabled()
          local enable_scripts = access.config.defaultAllowScript
          local nsrow  = db.nsMatchDomain(hostname)

          if nsrow then
            enable_scripts = nsrow.enable_scripts
          end
          return string.format( "<span foreground=\"%s\">Scripts %sabled</span>"
                              , util.boolToColor(enable_scripts)
                              , enable_scripts and "En" or "Dis"
                              )
        end


        local rows = {{arePluginsEnabled, plugin = true }
                     ,{areScriptsEnabled, script = true } 

        -- Build plugin/script entries
                     ,{ ":: domain","reason",title = true }}

        -- Build domain/hosts + paths list
        for domain,paths in pairs(record.requestRecord[view]) do
            local function domainCol()
              local isDomain = cache.getDomain(domain)
              local isDomainByHost = cache.getDomainByHost(hostname,domain)
              return string.format("<span foreground=\"%s\">%s</span>"
                                  , util.boolToColor( isDomain ~= nil and isDomain.value
                                                    or isDomainByHost ~= nil and isDomainByHost.value
                                                    )
                                  , domain
                                  )
            end
            local function domainColString()
              local isDomain = cache.getDomain(domain)
              local isDomainByHost = cache.getDomainByHost(hostname,domain)
              local domainString = ""

              if isDomain and isDomain.value ~= nil then
                if isDomain.value then
                  domainString = "+domain"
                else
                  domainString = "-domain"
                end
              end

              if isDomainByHost and isDomainByHost.value ~= nil then 
                if isDomainByHost.value then
                  domainString = domainString .. " +domain by host"
                else 
                  domainString = domainString .. " -domain by host"
                end
              end

              return domainString
            end
            table.insert(rows, { domainCol , domainColString, domain = domain} )
            for path,accessReq in pairs(paths) do
              local function pathCol()
                local isPath       = cache.getPath(domain,path)
                local isPathByHost = cache.getPathByHost(hostname,domain,path)
                return string.format(" <span foreground=\"%s\">%s</span>"
                                    ,util.boolToColor( isPath ~= nil and isPath.value
                                                     or isPathByHost ~= nil and isPathByHost.value
                                                     or accessReq.reason.defaults
                                                     )
                                    ,path
                                    )
              end
              local function pathColReason()
                local isPath       = cache.getPath(domain,path)
                local isPathByHost = cache.getPathByHost(hostname,domain,path)

                local pathString = ""

                if isPath and isPath.value ~= nil then
                  if isPath.value then
                    pathString = "+path"
                  else
                    pathString = "-path"
                  end
                end

                if isPathByHost and isPathByHost.value ~= nil then 
                  if isPathByHost.value then
                    pathString = pathString .. " +path by host"
                  else 
                    pathString = pathString .. " -path by host"
                  end
                end

                if accessReq.reason.defaults then
                  pathString = pathString .. " +defaults"
                end
                return pathString
              end
              table.insert(rows, {pathCol
                                 , pathColReason
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
