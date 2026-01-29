# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a personal AwesomeWM configuration written in Lua for Linux desktop environments. It provides a complete desktop environment with custom widgets, animations, and integrations.

## Key Architecture

### Module Structure
- `rc.lua` - Main entry point that loads all modules in order: signals → configuration → bindings → UI
- `configuration/` - System configuration (wallpaper, tags, layouts, client rules)
- `bindings/` - Keyboard shortcuts and mouse bindings
- `signals/` - Background processes and data providers (battery, wifi, media, weather, etc.)
- `ui/` - All visual components (bar, popups, lockscreen, control center)
- `helpers/` - Utility functions for animations, colors, and system controls
- `theme/` - Color scheme and styling based on Xresources

### Signal-Driven Architecture
The configuration uses AwesomeWM's signal system extensively. Signals must be loaded before UI widgets to ensure data providers are ready when widgets initialize.

### Configuration Variables
All user-customizable settings are centralized in `configuration/variables.lua` including:
- Applications (editor, terminal, file manager)
- Geographic coordinates for weather/redshift
- Optional features (video wallpaper, dominant colors, calendar integration)

## Development Commands

### Testing Configuration
```bash
# Test configuration syntax
awesome -k

# Restart AwesomeWM
echo 'awesome.restart()' | awesome-client

# Check for Lua syntax errors in specific files
luac -p <file.lua>
```

### Dependencies Management
```bash
# Install main dependencies (EndeavourOS/Arch)
pikaur -S awesome-git acpi upower pipewire playerctl pamixer brightnessctl

# Install optional dependencies
pikaur -S mpv xwinwrap-git python-pipx gcalendar

# Install dominant colors script for media widget
pipx install git+https://github.com/pablonoya/dominantcolors.git
```

## Key Components

### Autostart System
`configuration/autostart.sh` manages system services using a `start()` function that checks if processes are already running before launching them.

### Theme System
Colors are loaded from `~/.Xresources` and mapped to semantic names in `theme/theme.lua`. The theme includes custom color aliases like planetary names (mars=red, jupiter=green, etc.).

### Widget Architecture
- Widgets are signal-driven and update automatically
- Most widgets support animations using the Rubato library
- Complex widgets like media controls change colors based on album art

### Optional Features
Several features can be enabled in `configuration/variables.lua`:
- Video wallpaper with auto-pausing
- Weather integration (requires OpenWeather API key)
- Google Calendar events (requires gcalendar)
- Media controls with dominant color extraction

## File Organization

- UI components follow a hierarchical structure: `ui/component/subcomponent/`
- Each major UI section has its own `init.lua` that requires all submodules
- Configuration modules are kept separate from UI to maintain clean separation of concerns
- Helper functions are organized by category (animation, color, system controls, etc.)