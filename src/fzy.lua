-- Attempt to load the native version
local ok, fzy_module = pcall(require, "fzy_native")

-- Otherwise, fall back on the lua version.
if not ok then fzy_module = require("fzy_lua") end

-- Publish the type of the active implementation
fzy_module.implementation = ok and "native" or "lua"

return fzy_module
