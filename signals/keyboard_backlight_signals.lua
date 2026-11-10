-- Keyboard backlight through brightnessctl (no root needed: it goes through logind).
-- Uses the first LED whose name contains "kbd_backlight" (e.g. tpacpi::kbd_backlight).
local spawn = require("awful.spawn")

local _signals = {}

local function run(args)
    spawn.easy_async(
        args, function(stdout)
            -- brightnessctl -m: device,class,current,percent%,max
            local percent = stdout:match(",(%d+)%%,")
            if percent then
                awesome.emit_signal("brightness::keyboard", tonumber(percent))
            end
        end
    )
end

local function device_args(...)
    return { "brightnessctl", "-m", "-d", "*kbd_backlight*", ... }
end

function _signals.up()
    run(device_args("set", "+1"))
end

function _signals.down()
    run(device_args("set", "1-"))
end

return _signals
