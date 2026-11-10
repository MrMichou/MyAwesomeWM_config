local beautiful = require("beautiful")

screen.connect_signal(
    "request::wallpaper", function(s)
        require("awful.wallpaper") {
            screen = s,
            bg = beautiful.black
        }
    end
)
