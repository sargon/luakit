-------------------------------------------------------
-- LockDown Cache handling                           --
-- (C) 2012 Daniel Ehlers <danielehlers@mindeye.net> --
-------------------------------------------------------

local pairs = pairs

module "lockdown.cache"

local cache = 
  { hosts   = {}
  , domains = {}
  , paths   = {}
  }

local function checkHostname(hostname) 
  if not cache.hosts[hostname] then
    cache.hosts[hostname] = 
      { domains = {}
      , paths   = {}
      , enable_scripts = nil -- TODO Cache this 
      , enable_plugins = nil -- TODO Cache this
      }
  end
end

local function checkPathByHostname(hostname,domain)
  checkHostname(hostname)
  if not cache.hosts[hostname].paths[domain] then
    cache.hosts[hostname].paths[domain] = {}
  end
end

function setDomainByHost(hostname,domain,allowed)
  checkHostname(hostname)
  cache.hosts[hostname].domains[domain] = 
    { value   = allowed
    , changed = "set"
    }
end

function getDomainByHost(hostname,domain)
  if cache.hosts[hostname] and cache.hosts[hostname].domains[domain] then
    return cache.hosts[hostname].domains[domain]
  end
  return nil
end

function resetDomainByHost(hostname,domain)
  cache.hosts[hostname].domains[domain] = 
    { value   = nil
    , changed = "reset"
    }
end

function setPathByHost(hostname,domain,path,allowed)
  checkPathByHostname(hostname,domain)
  cache.hosts[hostname].paths[domain][path] =
    { value   = allowed
    , changed = "set"
    }
end

function getPathByHost(hostname,domain,path)
  if cache.hosts[hostname] 
  and cache.hosts[hostname].paths[domain] 
  and cache.hosts[hostname].paths[domain][path] then
    return cache.hosts[hostname].paths[domain][path]
  end
  return nil
end

function resetPathByHost(hostname,domain,path)
  cache.hosts[hostname].paths[domain][path] =
    { value   = nil
    , changed = "reset"
    }
end

function setDomain(domain,allowed)
  cache.domains[domain] = 
    { value   = allowed
    , changed = "set"
    }
end

function getDomain(domain)
  if cache.domains[domain] then
    return cache.domains[domain]
  end
  return nil
end

function resetDomain(domain)
  cache.domains[domain] = 
    { value   = nil
    , changed = "reset"
    }
end

function setPath(domain,path,allowed)
  if not cache.paths[domain] then
    cache.paths[domain] = {}
  end
  cache.paths[domain][path] =
    { value   = allowed
    , changed = "set"
    }
end

function togglePath(domain,path)
  local get = getPath(domain,path)
  if get and get.value then
      setPath(domain,path,not get.value)
  else
      setPath(domain,path, true)
  end

end

function getPath(domain,path)
  if cache.paths[domain] and cache.paths[domain][path] then
    return cache.paths[domain][path]
  end
  return nil
end

function resetPath(domain,path)
  cache.paths[domain][path] =
    { value   = nil
    , changed = "reset"
    }
end
