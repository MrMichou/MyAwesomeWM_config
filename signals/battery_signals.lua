local spawn = require("awful.spawn")
local gtimer = require("gears.timer")

local function emit_battery_state(battery_file)
    spawn.easy_async_with_shell(
        "sleep 0.5; cat " .. battery_file, function(stdout)
            awesome.emit_signal("signal::charger", stdout == "Charging\n")
        end
    )
end

spawn.easy_async_with_shell(
    "ls /sys/class/power_supply/BAT*/status 2>/dev/null | head -1 || false",
        function(battery_file, _, __, exit_code)
            -- No battery status found
            if exit_code ~= 0 then
                return
            end

            battery_file = battery_file:gsub("\n", "")  -- Remove newline

            -- Check actual state
            emit_battery_state(battery_file)

            -- Listen to battery events
            spawn.with_line_callback(
                [[ sh -c "acpi_listen 2> /dev/null | grep --line-buffered 'battery'" ]], {
                    stdout = function(line)
                        emit_battery_state(battery_file)
                    end
                }
            )
        end
)

spawn.easy_async_with_shell(
    "ls /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 || false",
        function(battery_file, _, __, exit_code)
            -- No battery capacity found
            if exit_code ~= 0 then
                return
            end

            battery_file = battery_file:gsub("\n", "")  -- Remove newline

            -- Periodically get battery info
            local timer = gtimer {
                timeout = 40,
                call_now = true,
                callback = function()
                    spawn.easy_async_with_shell(
                        "cat " .. battery_file, function(stdout)
                            awesome.emit_signal("signal::battery", tonumber(stdout))
                        end
                    )
                end
            }

            awesome.connect_signal(
                "signal::charger", function(is_charging)
                    timer.timeout = is_charging and 40 or 60
                    timer:again()
                end
            )
        end
)
