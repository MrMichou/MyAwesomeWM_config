# Lua 5.5 patches for third-party submodules

`awesome-git` is now built against Lua 5.5 with `lua-lgi-git`. The pinned
commits of `module/bling`, `module/rubato` and `away` need small fixes that
their upstreams do not have:

| Patch | Fix |
|-------|-----|
| `bling.patch` | `layout/init.lua`: no assignment to a `for` loop variable (compile error in 5.5). `signal/playerctl/playerctl_lib.lua`: tolerate metadata without `xesam:artist`. |
| `rubato.patch` | `timed.lua`: pass an integer interval to `GLib.timeout_add` (lgi-git rejects fractional values, which broke every slide animation). |
| `away.patch` | `third_party/widget/cal.lua`: no assignment to a `for` loop variable. |

After cloning and checking out the submodules, run:

```sh
patches/lua55/apply.sh
```
