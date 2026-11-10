local spawn = require("awful.spawn")
local gfs = require("gears.filesystem")
local beautiful = require("beautiful")
local naughty = require("naughty")

-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
naughty.connect_signal(
    "request::display_error", function(message, startup)
        naughty.notification {
            urgency = "critical",
            title = "Oops, an error happened" .. (startup and " during startup!" or "!"),
            message = message
        }
    end
)

dpi = beautiful.xresources.apply_dpi

-- Autostart programs
do
    local variables = require("configuration.variables")
    spawn.with_shell(string.format(
        "LATITUDE=%s LONGITUDE=%s %sconfiguration/autostart.sh",
        variables.latitude, variables.longitude, gfs.get_configuration_dir()
    ))
end

-- Theme + Configs
beautiful.init(gfs.get_configuration_dir() .. "theme/theme.lua")
require("bindings")
require("configuration")

-- Load a module that may not be installed. A missing module is fine; one that is there but
-- fails to load is reported once the session is up, instead of vanishing silently.
local function optional(name)
    local ok, err = pcall(require, name)
    if ok or tostring(err):find("module '" .. name .. "' not found", 1, true) then
        return
    end
    require("gears.timer").delayed_call(function()
        naughty.notification {
            urgency = "critical",
            title = "Optional module failed to load: " .. name,
            message = tostring(err)
        }
    end)
end

-- Import Signals + UI (signals first to be ready when widgets load)
require("signals")
-- Optional Claude Code "constellation" desktop layer (live sessions + resources they touch).
-- Must load before ui: non-ontop wiboxes stack in the order they are shown, so loading it
-- later would cover the bar and docks.
optional("ui.desktop.claude_constellation")
require("ui")


-- Garbage Collector Settings (optimized for performance)
-- Lua 5.5 removed the "setpause"/"setstepmul" options in favour of "param".
if not pcall(collectgarbage, "param", "pause", 160) then
    collectgarbage("setpause", 160)
    collectgarbage("setstepmul", 400)
else
    collectgarbage("param", "stepmul", 400)
end
