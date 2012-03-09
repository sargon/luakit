-------------------------------------------------------
-- LockDown Access handling                          --
-- (C) 2012 Daniel Ehlers <danielehlers@mindeye.net> --
-------------------------------------------------------
--
local cache = require "lockdown.cache"
local util = require "lockdown.util"

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

local function match(cacheResult,value)
  return cacheResult ~= nil 
     and cacheResult.value ~= nil
     and cacheResult.value == value
end

local function notCached(cacheResult) 
  return cacheResult == nil
end

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
  local isDomainByHost = cache.getDomainByHost(hostname,domain)
  local isPathByHost = cache.getPathByHost(hostname,domain,path)

  -- ALLOW ------------------------------------------------

  -- Domain 
  if match(isDomain,true) then
    requestCommit = true
    accessReason.domain = true
  else
    if notCached(isDomain) then
    -- TODO database lookup
    end
  end

  -- Path
  if match(isPath,true) then
    requestCommit = true
    accessReason.path = true
  else 
    if notCached(isPath) then
    -- TODO database lookup
    end
  end

  -- DENY -------------------------------------------------
  
  -- Domain 
  if match(isDomain,false)  then
    requestCommit = false
    accessReason.domain = false
  end

  -- Path
  if match(isPath,false) then
    requestCommit = false
    accessReason.path = false
  end

  -- ALLOW Host -------------------------------------------
 
  -- DomainByHost
  if match(isDomainByHost,true) then
    requestCommit = true
    accessReason.domainByHost = true
  else 
    if notCached(isDomainByHost) then
    -- TODO database lookup
    end
  end

  -- PathByHost
  if match(isPathByHost,true) then
    requestCommit = true
    accessReason.pathByHost = true
  else
    if notCached(isPathByHost) then
    -- TODO database lookup
    end
  end

  -- DENY Host --------------------------------------------

  -- DomainByHost
  if match(isDomainByHost,false) then
    requestCommit = false
    accessReason.domainByHost = false
  end

  -- PathByHost
  if match(isPathByHost,false) then
    requestCommit = false
    accessReason.pathByHost = false
  end

  -- RESULT -----------------------------------------------

  return { result = requestCommit
         , request = requestURI 
         , reason = accessReason 
         }
end
