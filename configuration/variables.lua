local gfs = require("gears.filesystem")

local HOME = os.getenv("HOME")

local variables = {
	editor = "neovim",
	file_manager = "nautilus",
	terminal = "terminator",

	pfp = gfs.get_configuration_dir() .. "ui/assets/kirbeats.jpg",

	latitude = 12.345,
	longitude = -67.890,

	-- Optional variables
	-- Video wallpaper
	-- videowallpaper_path = HOME .. "/Videos/cyberpunk-city-pixel.mp4",
	-- videowallpaper_vertical_path = HOME .. "/Videos/cyberpunk-city-pixel-vertical.mp4",

	-- Dominantcolors script path
	dominantcolors_path = HOME .. "/.local/bin/dominantcolors",

	-- gcalendar requires output in json
	gcalendar_command = "gcalendar --output json --no-of-days 3",

	-- OpenWeather api key
	-- weather_api_key = "y0ur4p1k3yc0m35h3r3"
}

-- Personal values (coordinates, API keys...) go in configuration/variables_local.lua, which is
-- not tracked: a file returning a table whose keys override the ones above.
local ok, overrides = pcall(dofile, gfs.get_configuration_dir() .. "configuration/variables_local.lua")
if ok and type(overrides) == "table" then
	for key, value in pairs(overrides) do
		variables[key] = value
	end
end

return variables
