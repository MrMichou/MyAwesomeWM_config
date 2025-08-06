local awful = require("awful")
local beautiful = require("beautiful")
local gtimer = require("gears.timer")
local naughty = require("naughty")
local wibox = require("wibox")

local color_helpers = require("helpers.color-helpers")

local wordclock = require("ui.lockscreen.wordclock")
local lockscreen_body = require("ui.lockscreen.lockscreen_body")
local grab_password = require("ui.lockscreen.grab_password")
local power_buttons = require("ui.lockscreen.power_buttons")
local weather_box = require("ui.lockscreen.weather_box")
local media_controls_box = require("ui.lockscreen.media_controls_box")

local last_hour
local last_minute
local active_color

local function update_time()
	local hour, min = os.date("%H:%M"):match("(%d+):(%d+)")
	local hour = tonumber(hour)
	local min = tonumber(min)

	-- update only if time has changed
	if last_hour == hour and last_minute == min then
		return
	end

	active_color = color_helpers.get_color_by_time_of_day(hour)
	lockscreen_body:get_children_by_id("container")[1].border_color = active_color
	wordclock.update_clock(hour, min, active_color)

	last_hour = hour
	last_minute = min
end

local clock_timer = gtimer({
	timeout = 2,
	call_now = false,
	callback = update_time,
})

-- Add lockscreen to each screen
awful.screen.connect_for_each_screen(function(s)
	s.lockscreen = wibox({
		widget = {
			{
				lockscreen_body,
				{
					-- power_buttons,
					-- weather_box,
					-- media_controls_box,

					spacing = dpi(12),
					layout = wibox.layout.fixed.vertical,
				},
				spacing = dpi(12),
				layout = wibox.layout.fixed.horizontal,
			},
			widget = wibox.container.place,
		},
		visible = false,
		ontop = true,
		type = "splash",
		screen = s,
		-- bg = beautiful.black .. "FF",
		-- bg = beautiful.black .. "A0",
		bg = "00",
	})
end)

awesome.connect_signal("lockscreen::visible", function(visible)
	if visible then
		grab_password()
		update_time()
		clock_timer:start()
	else
		clock_timer:stop()
	end

	naughty.suspended = visible
	for s in screen do
		s.lockscreen.visible = visible
	end
end)

screen.connect_signal("request::wallpaper", function(s)
	awful.placement.maximize(s.lockscreen)
end)
