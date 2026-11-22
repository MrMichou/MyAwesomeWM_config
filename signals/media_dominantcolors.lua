local spawn = require("awful.spawn")

local variables = require("configuration.variables")
local playerctl = require("signals.playerctl")

local actual_colors

local function extract_dominantcolors(stdout, stderr)
    if stderr ~= "" then
        -- dominantcolors crashes on some album arts (e.g. tiny thumbnails with no
        -- repeated color); keep the current colors and log instead of notifying.
        io.stderr:write("dominantcolors failed: " .. (stderr:match("([^\n]+)%s*$") or stderr) .. "\n")
        return
    end

    if stdout == "" or not string.match(stdout, "^#") or actual_colors == stdout then
        return
    end

    local colors = {}
    for color in stdout:gmatch("[^\n]+") do
        table.insert(colors, color)
    end

    awesome.emit_signal("media::dominantcolors", colors)
    actual_colors = stdout
end

playerctl:connect_signal(
    "metadata", function(_, title, artist, album_path, album, new)
        if not album_path or album_path == "" then
            return
        end

        if not actual_colors or new == true then
            spawn.easy_async_with_shell(
                variables.dominantcolors_path .. " -c 3.5 " .. album_path, extract_dominantcolors
            )
        end
    end
)
