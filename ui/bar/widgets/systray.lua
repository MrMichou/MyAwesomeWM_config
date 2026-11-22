-- Collapsible systray with one "featured" icon that stays visible.
--
-- Tray icons are foreign X windows: awesome draws them all as one block and
-- they cannot be hidden individually. Trick: the tray lives in a small
-- dedicated wibox ("peek") laid over a placeholder in the bar. A window clips
-- its children, so by shrinking the peek and shifting the tray inside it,
-- only the featured icon is visible when collapsed. Unfolding animates the
-- peek's width and the shift together, which reveals the other icons.
--
--   hover the chevron    : unfold (folds back COLLAPSE_DELAY after leaving)
--   left-click chevron   : pin open
--   right-click chevron  : choose the featured icon (persisted)
local awful_menu = require("awful.menu")
local awful_screen = require("awful.screen")
local awful_spawn = require("awful.spawn")
local only_on_screen = require("awful.widget.only_on_screen")
local beautiful = require("beautiful")
local gears_filesystem = require("gears.filesystem")
local gears_timer = require("gears.timer")
local wibox = require("wibox")
local wibox_container = require("wibox.container")
local wibox_layout = require("wibox.layout")
local wibox_widget = require("wibox.widget")
local wbase = require("wibox.widget.base")

local helpers = require("helpers")
local rubato = require("module.rubato")
local text_icon = require("ui.widgets.text-icon")

-- Delay before folding the tray back once the pointer has left it.
local COLLAPSE_DELAY = 0.8
-- Duration of the unfold/fold animation, in seconds.
local ANIMATION_DURATION = 0.25
-- Icon kept visible when nothing has been chosen yet.
local DEFAULT_FEATURED = "nm-applet"

local STATE_FILE = gears_filesystem.get_cache_dir() .. "featured_tray_icon"
local ICONS_HELPER = gears_filesystem.get_configuration_dir() .. "helpers/tray_icons.py"

local CHEVRON_LEFT = "\u{e5cb}"
local CHEVRON_RIGHT = "\u{e5cc}"
local PIN = "\u{e6aa}"

local icon_size = 24
local tray_screen = awful_screen.focused()

local expanded = false
local pinned = false
local progress = 0 -- 0 = folded, 1 = unfolded (animated)

-- WM_CLASS of the tray icons, left to right (filled by the python helper),
-- and a readable label per class for the selection menu.
local icon_classes = {}
local icon_labels = {}

local featured
do
    local f = io.open(STATE_FILE, "r")
    if f then
        featured = f:read("*l")
        f:close()
        if not featured or featured == "" then
            featured = false -- explicitly "none"
        end
    else
        featured = DEFAULT_FEATURED
    end
end

local function save_featured()
    local f = io.open(STATE_FILE, "w")
    if f then
        f:write(featured or "", "\n")
        f:close()
    end
end

---------------------------------------------------------------------------
-- Geometry
---------------------------------------------------------------------------

local function spacing()
    return beautiful.systray_icon_spacing or 0
end

local function full_width()
    local n = awesome.systray()
    if n == 0 then
        return 0
    end
    return (icon_size + spacing()) * n - spacing()
end

-- 0-based position of the featured icon in the tray, or nil.
local function featured_index()
    if not featured then
        return nil
    end
    for i, cls in ipairs(icon_classes) do
        if cls == featured then
            return i - 1
        end
    end
    return nil
end

-- Visible width and tray shift for the current animation progress.
local function current_geometry()
    local full = full_width()
    local k = featured_index()
    if k and k < awesome.systray() then
        local width = icon_size + (full - icon_size) * progress
        local shift = k * (icon_size + spacing()) * (1 - progress)
        return math.floor(width + 0.5), math.floor(shift + 0.5)
    end
    return math.floor(full * progress + 0.5), 0
end

---------------------------------------------------------------------------
-- Peek window holding the real tray
---------------------------------------------------------------------------

local tray = wibox_widget.systray()
tray:set_base_size(icon_size)

-- Lays the tray out at its full natural width, shifted left by `shift`.
local shifter = wbase.make_widget(nil, nil, { enable_properties = true })
shifter.shift = 0
function shifter:fit(_, w, h)
    return w, h
end
function shifter:layout(_, _, height)
    return { wbase.place_widget_at(tray, -self.shift, 0, full_width(), height) }
end

local peek -- created lazily, after the bars, so it stacks above them
local placeholder_geometry = {} -- [screen] = { x, y, width, height } in bar coords

local function current_bg()
    return progress > 0 and beautiful.focus or beautiful.wibar_bg
end

local function update_peek()
    if not peek then
        return
    end
    local s = tray_screen
    local bar = s and s.valid and s.bar
    local geo = s and placeholder_geometry[s]
    local width, shift = current_geometry()

    if not bar or not bar.visible or not geo or width < 1 then
        -- Nothing to show: park the tray just above the screen instead of
        -- unmapping it, so its icons stay mapped (the helper can read their
        -- order) and the peek still belongs to the tray's screen.
        if s and s.valid then
            shifter.shift = 0
            shifter:emit_signal("widget::layout_changed")
            peek:geometry {
                x = s.geometry.x,
                y = s.geometry.y - icon_size - 100,
                width = math.max(1, full_width()),
                height = icon_size
            }
            peek.visible = true
        end
        return
    end

    shifter.shift = shift
    shifter:emit_signal("widget::layout_changed")
    peek.bg = current_bg()
    peek:geometry {
        x = bar.x + geo.x,
        y = bar.y + geo.y + math.floor((geo.height - icon_size) / 2),
        width = width,
        height = icon_size
    }
    peek.visible = true
end

-- Non-ontop wiboxes stack in the order they were mapped: remap the peek so it
-- is above a bar that was (re)created or shown after it.
local function raise_peek()
    if peek and peek.visible then
        peek.visible = false
        peek.visible = true
    end
end

---------------------------------------------------------------------------
-- Bar widgets
---------------------------------------------------------------------------

-- Reserves the space in the bar and records where it is drawn.
local placeholder = wbase.make_widget(nil, nil, { enable_properties = true })
function placeholder:fit()
    local width = current_geometry()
    return width, icon_size
end
function placeholder:draw(context, cr, width, height)
    local x, y = wbase.rect_to_device_geometry(cr, 0, 0, width, height)
    local s = context.screen
    local old = placeholder_geometry[s]
    if not old or old.x ~= x or old.y ~= y or old.width ~= width or old.height ~= height then
        placeholder_geometry[s] = { x = x, y = y, width = width, height = height }
        gears_timer.delayed_call(update_peek)
    end
end

local chevron = text_icon {
    markup = CHEVRON_LEFT,
    size = 18,
    fill = 0
}

local systray = wibox_widget {
    {
        {
            {
                {
                    placeholder,
                    chevron,
                    spacing = dpi(4),
                    layout = wibox_layout.fixed.horizontal
                },
                margins = dpi(4),
                widget = wibox_container.margin
            },
            widget = wibox_container.place
        },
        id = "background",
        shape = helpers.rrect(beautiful.border_radius),
        widget = wibox_container.background
    },
    screen = tray_screen,
    widget = only_on_screen
}

local function update_chevron()
    chevron.markup = pinned and PIN or (expanded and CHEVRON_RIGHT or CHEVRON_LEFT)
end

local function redraw()
    systray.background.bg = progress > 0 and beautiful.focus or beautiful.transparent
    local bg = current_bg()
    if beautiful.bg_systray ~= bg then
        beautiful.bg_systray = bg
        tray:emit_signal("widget::redraw_needed")
    end
    placeholder:emit_signal("widget::layout_changed")
    update_peek()
end

---------------------------------------------------------------------------
-- Animation and hover logic
---------------------------------------------------------------------------

local animation = rubato.timed {
    duration = ANIMATION_DURATION,
    easing = rubato.easing.quadratic,
    subscribed = function(pos)
        progress = math.max(0, math.min(1, pos))
        redraw()
    end
}

local function set_expanded(value)
    if expanded == value then
        return
    end
    expanded = value
    update_chevron()
    animation.target = value and 1 or 0
end

local function point_in(geo, x, y)
    return geo and x >= geo.x and x < geo.x + geo.width and y >= geo.y and y < geo.y + geo.height
end

-- Pointer over the pill in the bar, or over the peek (tray icons are foreign
-- windows, so enter/leave signals alone are not reliable there).
local function pointer_over_systray()
    local coords = mouse.coords()
    if peek and peek.visible and point_in(peek:geometry(), coords.x, coords.y) then
        return true
    end
    local bar = mouse.screen and mouse.screen.bar
    if not bar or not bar.visible then
        return false
    end
    local x, y = coords.x - bar.x, coords.y - bar.y
    if x < 0 or y < 0 or x >= bar.width or y >= bar.height then
        return false
    end
    for _, entry in ipairs(bar:find_widgets(x, y)) do
        if entry.widget == systray then
            return true
        end
    end
    return false
end

-- Repeating timer: keeps polling while the pointer rests on the tray, and
-- stops itself once the tray is folded (or pinned).
local collapse_timer = gears_timer {
    timeout = COLLAPSE_DELAY,
    callback = function(self)
        if pinned or not expanded then
            self:stop()
        elseif not pointer_over_systray() then
            set_expanded(false)
            self:stop()
        end
    end
}

local function stop_collapse()
    if collapse_timer.started then
        collapse_timer:stop()
    end
end

local function start_collapse()
    if not pinned and expanded then
        collapse_timer:again()
    end
end

-- Hovering the pill (chevron area) unfolds. Hovering the featured icon alone
-- does not, so it can be clicked without the tray moving under the pointer.
systray:connect_signal("mouse::enter", function()
    stop_collapse()
    set_expanded(true)
end)
systray:connect_signal("mouse::leave", start_collapse)

---------------------------------------------------------------------------
-- Featured icon selection
---------------------------------------------------------------------------

local refreshing = false
local function refresh_icon_classes()
    if refreshing then
        return
    end
    refreshing = true
    awful_spawn.easy_async({ "python3", "-I", ICONS_HELPER }, function(stdout)
        refreshing = false
        local list, labels = {}, {}
        for line in stdout:gmatch("[^\n]+") do
            local cls, name = line:match("^([^\t]*)\t?(.*)$")
            list[#list + 1] = cls
            labels[cls] = (name ~= "" and name) or cls
        end
        -- The helper only sees the tray while it is mapped; keep the last
        -- known order otherwise.
        if #list > 0 then
            icon_classes = list
            icon_labels = labels
            redraw()
        end
    end)
end

local refresh_soon = gears_timer {
    timeout = 0.5,
    single_shot = true,
    callback = refresh_icon_classes
}

local menu
local function show_featured_menu()
    if menu then
        menu:hide()
    end
    local items = {
        {
            (featured and "    " or "● ") .. "None",
            function()
                featured = false
                save_featured()
                redraw()
            end
        }
    }
    local seen = {}
    for _, cls in ipairs(icon_classes) do
        if not seen[cls] then
            seen[cls] = true
            items[#items + 1] = {
                (featured == cls and "● " or "    ") .. (icon_labels[cls] or cls),
                function()
                    featured = cls
                    save_featured()
                    redraw()
                end
            }
        end
    end
    menu = awful_menu { items = items, theme = { width = dpi(200) } }
    menu:show()
end

chevron:connect_signal("button::press", function(_, _, _, button)
    if button == 3 then
        show_featured_menu()
    elseif button == 1 then
        pinned = not pinned
        update_chevron()
        if pinned then
            stop_collapse()
            set_expanded(true)
        else
            start_collapse()
        end
    end
end)

---------------------------------------------------------------------------
-- Wiring
---------------------------------------------------------------------------

awesome.connect_signal("systray::update", function()
    refresh_soon:again()
    redraw()
end)

client.connect_signal("focus", function()
    local s = awful_screen.focused()
    if s == tray_screen then
        return
    end
    tray_screen = s
    icon_size = s.geometry.height > s.geometry.width and 20 or 24
    tray:set_base_size(icon_size)
    tray:set_screen(s)
    systray.screen = s
    redraw()
end)

local function watch_bar(s)
    if s.bar and not s.bar._peek_watched then
        s.bar._peek_watched = true
        s.bar:connect_signal("property::visible", function()
            update_peek()
            raise_peek()
        end)
        s.bar:connect_signal("property::geometry", update_peek)
    end
end

-- Create the peek once the bars exist so it is stacked above them.
gears_timer.delayed_call(function()
    beautiful.systray_max_rows = 1
    peek = wibox {
        type = "dock",
        visible = false,
        bg = current_bg(),
        widget = shifter
    }
    peek:connect_signal("mouse::enter", function()
        if expanded then
            stop_collapse()
        end
    end)
    peek:connect_signal("mouse::leave", start_collapse)

    for s in screen do
        watch_bar(s)
    end
    tray:set_screen(tray_screen)
    redraw()
    -- Give the tray a moment to map before reading the icon order.
    gears_timer.start_new(1, function()
        refresh_icon_classes()
    end)
end)

screen.connect_signal("request::desktop_decoration", function(s)
    gears_timer.delayed_call(function()
        watch_bar(s)
        raise_peek()
        update_peek()
    end)
end)

return {
    systray,
    left = dpi(4),
    right = dpi(4),
    widget = wibox_container.margin
}
