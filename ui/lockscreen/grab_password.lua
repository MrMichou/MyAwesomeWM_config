local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")

local config_dir = gears.filesystem.get_configuration_dir()
package.cpath = package.cpath .. ";" .. config_dir .. "ui/lockscreen/lib/?.so;"
local pam = require("liblua_pam")

local lock_animation = require("ui.lockscreen.lock_animation")

local keygrabber_instance = nil
local password_buffer = ""

local function check_password()
    if pam.auth_current_user(password_buffer) then
        lock_animation.reset()
        password_buffer = ""
        if keygrabber_instance then
            keygrabber_instance:stop()
            keygrabber_instance = nil
        end
        awesome.emit_signal("lockscreen::visible", false)
    else
        lock_animation.fail()
        password_buffer = ""
    end
end

local function reset_input()
    lock_animation.reset()
    password_buffer = ""
end

local function stop_password_grab()
    if keygrabber_instance then
        keygrabber_instance:stop()
        keygrabber_instance = nil
    end
    password_buffer = ""
    lock_animation.reset()
end

local function grab_password()
    -- Prevent multiple instances
    if keygrabber_instance then
        return
    end

    password_buffer = ""
    lock_animation.reset()

    keygrabber_instance = awful.keygrabber {
        autostart = true,
        keypressed_callback = function(self, modifiers, key, event)
            -- Prevent Awesomewm restart
            if gears.table.hasitem(modifiers, "Control") and
               gears.table.hasitem(modifiers, "Mod4") and key == "r" then
                reset_input()
                return
            end

            if key == "Return" then
                check_password()
            elseif key == "Escape" then
                reset_input()
            elseif key == "BackSpace" then
                if #password_buffer > 0 then
                    password_buffer = password_buffer:sub(1, -2)
                    lock_animation.key_animation("remove")
                end
            elseif #key == 1 then
                -- Only accept single character keys
                password_buffer = password_buffer .. key
                lock_animation.key_animation("insert")
            end
        end,
        stop_key = nil, -- Don't auto-stop on any key
        stop_event = "press",
    }
end

-- Listen for lockscreen visibility changes to cleanup keygrabber
awesome.connect_signal("lockscreen::visible", function(visible)
    if not visible then
        stop_password_grab()
    end
end)

return grab_password
