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
spawn.with_shell(gfs.get_configuration_dir() .. "configuration/autostart.sh")

-- Theme + Configs
beautiful.init(gfs.get_configuration_dir() .. "theme/theme.lua")
require("bindings")
require("configuration")

-- Import Signals + UI (signals first to be ready when widgets load)
require("signals")
-- Optional Claude Code "constellation" desktop layer (live sessions + resources they touch).
-- Must load before ui: non-ontop wiboxes stack in the order they are shown, so loading it
-- later would cover the bar and docks.
pcall(require, "ui.desktop.claude_constellation")
require("ui")

-- Optional Claude Code desktop crab pet (walks the screen edge while Claude works).
-- pcall-guarded so a pet error can never bring down the WM session.
pcall(require, "ui.bar.widgets.claude_status.crab")

-- Garbage Collector Settings (optimized for performance)
-- Lua 5.5 removed the "setpause"/"setstepmul" options in favour of "param".
if not pcall(collectgarbage, "param", "pause", 160) then
    collectgarbage("setpause", 160)
    collectgarbage("setstepmul", 400)
else
    collectgarbage("param", "stepmul", 400)
end
