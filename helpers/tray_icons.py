#!/usr/bin/env python3
"""Print awesome's systray icons in display order (left to right), one per line:
"<WM_CLASS>\t<label>" where label is the process name when the class is not
meaningful (e.g. "__main__.py" for Python apps).

Awesome exposes only the number of tray icons to Lua, so this inspects the X
tree: the systray is a window owned by awesome whose children are the
embedded icon windows. Requires python-xlib.
"""
from Xlib import X, display, error


def wm_class(win):
    try:
        cls = win.get_wm_class()
    except error.XError:
        return None
    return cls[0] if cls else None


def window_pid(d, win):
    """_NET_WM_PID of the icon window, else of its group/client leader."""
    pid_atom = d.intern_atom("_NET_WM_PID")
    candidates = [win]
    try:
        hints = win.get_wm_hints()
        if hints and hints.flags & 64:  # WindowGroupHint
            candidates.append(d.create_resource_object("window", hints.window_group.id))
    except Exception:
        pass
    try:
        leader = win.get_full_property(d.intern_atom("WM_CLIENT_LEADER"), X.AnyPropertyType)
        if leader:
            candidates.append(d.create_resource_object("window", leader.value[0]))
    except Exception:
        pass
    for w in candidates:
        try:
            prop = w.get_full_property(pid_atom, X.AnyPropertyType)
            if prop:
                return prop.value[0]
        except Exception:
            pass
    raise LookupError("no pid")


def label(d, win, cls):
    if not cls.startswith("__"):
        return cls
    try:
        pid = window_pid(d, win)
        with open(f"/proc/{pid}/cmdline", "rb") as f:
            args = [a.decode(errors="replace") for a in f.read().split(b"\0") if a]
        # "python /usr/bin/ulauncher" -> "ulauncher"
        for arg in args[1:] + args[:1]:
            name = arg.rsplit("/", 1)[-1]
            if name and not name.startswith("python") and not name.startswith("-"):
                return name
    except Exception:
        pass
    return cls


def main():
    d = display.Display()
    root = d.screen().root
    best = []
    # The systray window is reparented into the drawin (wibox) showing it, so
    # look at root children and their children.
    candidates = []
    for top in root.query_tree().children:
        candidates.append(top)
        try:
            candidates.extend(top.query_tree().children)
        except error.XError:
            pass
    for win in candidates:
        if wm_class(win) != "awesome":
            continue
        try:
            if win.get_attributes().map_state != X.IsViewable:
                continue
            children = win.query_tree().children
        except error.XError:
            continue
        icons = []
        for child in children:
            cls = wm_class(child)
            if not cls or cls == "awesome":
                icons = []
                break
            try:
                icons.append((child.get_geometry().x, cls, label(d, child, cls)))
            except error.XError:
                pass
        if len(icons) > len(best):
            best = icons
    for _, cls, name in sorted(best):
        print(f"{cls}\t{name}")


if __name__ == "__main__":
    main()
