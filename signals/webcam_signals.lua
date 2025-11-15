local spawn = require("awful.spawn")
local gtimer = require("gears.timer")

local last_value = false
local is_running = false

local function emit_signal()
    if is_running then
        return
    end
    is_running = true

    spawn.easy_async_with_shell(
        "fuser /dev/video0 2> /dev/null | awk '{print NF}'", function(stdout)
            local active = stdout ~= "" and tonumber(stdout) > 1

            if last_value ~= active then
                awesome.emit_signal("webcam::active", active)
                last_value = active
            end
            is_running = false
        end
    )
end

-- Webcam monitoring disabled by default - too resource intensive
-- local timer = gtimer {
--     timeout = 10,
--     call_now = false,
--     autostart = false,
--     callback = emit_signal
-- }
