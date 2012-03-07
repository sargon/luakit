-------------------------------------------------------
-- LockDown Access handling                          --
-- (C) 2012 Daniel Ehlers <danielehlers@mindeye.net> --
-------------------------------------------------------
--
local cache = require "lockdown.cache"
local util = require "lockdown.util"
local assert = assert

local lousy   = require "lousy"

module "lockdown.access"

config = 
  -- allow resources from sub domains
  { defaultAllowSubDomains    = true
  -- allow resources from sub domains of the same second level domain.
  , defaultAllowSLDSubDomains = true 
  -- allow resources from other (cross) domains
  , defaultAllowCrossDomains  = false
  -- allow scripts
  , defaultAllowScript        = false
  -- allow plugins
  , defaultAllowPlugins       = false
}

function evaluate(hostname,requestURI)

  local uri       = util.uriParse(requestURI)
  local domain = util.getHostname(uri)
  local path   = util.getPath(uri)

  -- configured default behaviour 
  local requestCommit = nil
  local accessReason = 
    { defaults = false
    , domain = false
    , path   = false
    , domainByHost = false
    , pathByHost = false
    }

  -- configured default behaviour 
  if util.isSubDomain(domain,hostname) then
    if config.defaultAllowSubDomains then 
      accessReason.defaults = true
      return { result = true
             , reason = accessReason
             , request = requestURI 
             }
    end
  else
    if util.isSLDSubDomain(domain,hostname) 
    and config.defaultAllowSLDSubDomains then 
      accessReason.defaults = true
      return { result = true
             , reason = accessReason
             , request = requestURI 
             }
    end
    requestCommit = config.defaultAllowCrossDomains
  end
 
  -- Cached values
  local isDomain = cache.getDomain(domain)
  local isPath = cache.getPath(domain,path)
  local isDomainByHost = cache.getDomainByHost(host,domain)
  local isPathByHost = cache.getPathByHost(host,domain,path)

  -- ALLOW ------------------------------------------------

  -- Domain 
  if isDomain ~= nil and isDomain.value then
    requestCommit = true
    accessReason.domain = true
  else
    -- TODO database lookup
  end

  -- Path
  if isPath ~= nil and isPath.value then
    requestCommit = true
    accessReason.path = true
  else 
    -- TODO database lookup
  end

  -- DENY -------------------------------------------------
  
  -- Domain 
  if isDomain ~= nil and not isDomain.value then
    requestCommit = false
    accessReason.domain = false
  end

  -- Path
  if isDomain ~= nil and not isPath.value then
    requestCommit = false
    accessReason.path = false
  end

  -- ALLOW Host -------------------------------------------
 
  -- DomainByHost
  if isDomainByHost ~= nil and isDomainByHost.value then
    requestCommit = true
    accessReason.domainByHost = true
  else 
    -- TODO database lookup
  end

  -- PathByHost
  if isPathByHost ~= nil and isPathByHost.value then
    requestCommit = true
    accessReason.pathByHost = true
  else 
    -- TODO database lookup
  end

  -- DENY Host --------------------------------------------

  -- DomainByHost
  if isDomainByHost ~= nil and isDomainByHost.value then
    requestCommit = false
    accessReason.domainByHost = false
  end

  -- PathByHost
  if isPathByHost ~= nil and isPathByHost.value then
    requestCommit = false
    accessReason.pathByHost = false
  end

  -- RESULT -----------------------------------------------

  return { result = requestCommit
         , request = requestURI 
         , reason = accessReason 
         }
end
