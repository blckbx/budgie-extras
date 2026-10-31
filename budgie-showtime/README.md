# Budgie ShowTime

Budgie Showtime is a digital desktop clock, showing time, and optionally, date. Textcolor of both can be set separately from the applet's menu.

Settings from Budgie Settings include text alignment, -color, -size, temporarily make the applet dragable for custom positioning, 12 hrs format, custom data formatting according to:

https://valadoc.org/glib-2.0/GLib.DateTime.format.html

Furthermore, gsettings overrides can be done for font (-family), left or right bottom positioning.

To set left-bottom:
xposition = 1
yposition = -1

To set right-bottom:
xposition = 2
yposition = -1

# Install
### Bitcoin service configuration

Copy the repository's `.env.example` to `.env` and replace `IP:PORT` with your
local service address. `.env` is ignored by Git. The API base URL excludes `/api`:

```dotenv
SHOWTIME_BITCOIN_API_URL=https://IP:PORT
```

Showtime reads configuration at startup, so restart it after changing the file.
An exported `SHOWTIME_BITCOIN_API_URL` takes precedence over file settings.
To choose a specific file, set `SHOWTIME_ENV_FILE` to its absolute path.
Otherwise Showtime reads `$XDG_CONFIG_HOME/budgie-showtime/.env` (normally
`~/.config/budgie-showtime/.env`), falling back to `.env` in its working directory.
For an installed panel applet, copy your local `.env` to that user configuration
directory; the panel's working directory need not be the repository.

Files support `KEY=value` assignments, optional matching single or double quotes,
blank lines, and full-line `#` comments. Shell expansion and inline comments are
not supported. Files are read as data, never executed. Without configuration,
Showtime retains the `https://IP:PORT` placeholder and logs a warning.

External BTC prices use Kraken's public BTC/USD and BTC/EUR last-trade prices
through the Tor SOCKS proxy at `127.0.0.1:9050`. If the request fails, Showtime
retains the last successful prices and marks them `(stale)`, or displays
`unavailable` if no prices have loaded yet. Request failures are logged.

Run from the repo's folder:

- `mkdir build && cd build`

- `meson --buildtype plain --prefix=/usr --libdir=/usr/lib`

- `ninja`

- `sudo ninja install`

