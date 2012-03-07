-------------------------------------------------------
-- Database handling for LockDown                    --
-- (C) 2012 Daniel Ehlers <danielehlers@mindeye.net> --
-------------------------------------------------------

local lousy      = require "lousy"
local string     = string
local sql_escape = lousy.util.sql_escape
local util = require "lockdown.util"
local boolToInt = util.boolToInt
local intToBool = util.intToBool

local capi = 
  { luakit  = luakit
  , sqlite3 = sqlite3
  }


module("lockdown.database")

create_tables = [[
CREATE TABLE IF NOT EXISTS ns_by_domain (
    id INTEGER PRIMARY KEY,
    domain TEXT,
    enable_scripts INTEGER,
    enable_plugins INTEGER
);
]]

db = capi.sqlite3{ filename = capi.luakit.data_dir .. "/lockdown.db" }
db:exec("PRAGMA synchronous = OFF; PRAGMA secure_delete = 1;")
db:exec(create_tables)

function nsMatchDomain(domain)
    local rows = db:exec(string.format("SELECT * FROM ns_by_domain "
        .. "WHERE domain == %s;", sql_escape(domain)))
    if rows[1] then 
      rows[1].enable_plugins = intToBool(rows[1].enable_plugins)
      rows[1].enable_scripts = intToBool(rows[1].enable_scripts)
      return rows[1] 
    end
end

function nsUpdate(id, field, value)
    db:exec(string.format("UPDATE ns_by_domain SET %s = %d WHERE id == %d;"
                         , field
                         , boolToInt(value), id
                         )
           )
end

function nsInsert(domain, enable_scripts, enable_plugins)
    db:exec(string.format("INSERT INTO ns_by_domain VALUES (NULL, %s, %d, %d);"
                         , sql_escape(domain)
                         , boolToInt(enable_scripts)
                         , boolToInt(enable_plugins)
                         )
           )
end
