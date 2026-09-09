# homebrew-hawdl

Homebrew tap for [hawdl](https://github.com/taross-f/hawdl) — a macOS daemon
that holds the `awdl0` interface down so AWDL stops sharing the radio with
Wi-Fi.

## Install

```sh
brew tap taross-f/hawdl
brew install --HEAD taross-f/hawdl/hawdl
```

`--HEAD` is required until the first tagged release: the formula builds from
`main` and has no stable stanza yet.

**Starting the daemon is a separate, mandatory step.** Changing interface flags
needs root, so `brew services` has to run as root too:

```sh
sudo brew services start hawdl
```

Without it, neither the `hawdl` CLI nor `HawdlBar.app` has anything to talk to.

## What gets installed

| | |
| --- | --- |
| `hawdld` | the daemon, into `bin` — normally run through `brew services` |
| `hawdl` | the CLI: `status` / `hold` / `release` / `watch` |
| `HawdlBar.app` | menu bar app, assembled into the formula's prefix |

**Launching the menu bar app is required.** Nothing launches it for you, and
until it is running there is no menu bar item — which looks exactly like the
app failing to install:

```sh
open "$(brew --prefix hawdl)/HawdlBar.app"
```

A bundle runs from wherever it lives, so that is enough. Linking it into
`/Applications` is optional convenience — Spotlight, Launchpad, and a sane
entry under System Settings -> General -> Login Items:

```sh
ln -sfn "$(brew --prefix hawdl)/HawdlBar.app" /Applications/HawdlBar.app
```

## Before you install

Holding AWDL down disables **AirDrop, Handoff, Sidecar, Universal Control and
Continuity Camera**. `hawdl release` puts it back, and stopping the daemon does
too — `hawdld` always restores the interface before it exits.

Building from source needs Xcode 15 or later and macOS 14 (Sonoma) or later.
If you would rather not compile, the
[releases](https://github.com/taross-f/hawdl/releases) carry a prebuilt
universal tarball instead.

## Updating

`brew upgrade` on its own will **never** update this. The formula is head-only,
and Homebrew does not check upstream for a HEAD install unless asked to — it
reports the package as up to date indefinitely:

```sh
brew update                                     # pull the latest formula
brew upgrade --fetch-HEAD taross-f/hawdl/hawdl  # --fetch-HEAD is not optional
```

`brew reinstall taross-f/hawdl/hawdl` is the blunter equivalent: it always
rebuilds from current HEAD, changed or not.

Neither restarts anything. Until you do, the daemon and the menu bar app are
both still running the previous binaries:

```sh
sudo brew services restart hawdl
pkill -x HawdlBar && open "$(brew --prefix hawdl)/HawdlBar.app"
```

Restarting the daemon brings awdl0 back up for a moment. That is deliberate:
`hawdld` restores the interface before exiting, then the new process re-applies
the hold from its state file. `hawdl status` reports the running daemon's
version, so it tells you whether the restart actually took.

## Uninstall

```sh
sudo brew services stop hawdl   # this brings awdl0 back up
rm -f /Applications/HawdlBar.app   # only if you linked it
brew uninstall hawdl
brew untap taross-f/hawdl
sudo rm -rf "/Library/Application Support/hawdl"
```

Confirm the interface came back — the flags should include `UP`:

```sh
ifconfig awdl0 | head -1
```

## Where things live

The formula lives here; everything else — source, issues, releases — is in
[taross-f/hawdl](https://github.com/taross-f/hawdl).

## License

The formula is MIT, matching hawdl itself.
