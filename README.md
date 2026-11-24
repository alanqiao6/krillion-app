# Krillion for iPhone

An unofficial iPhone app for [Krillion](https://krillion.io) and its multiplayer
mode, Puffer Party, that keeps the game readable while you type.

In Safari, opening the keyboard makes Krillion slide the whole game up, which
pushes the category and the other players' answers off the top of the screen.
This app shows the real krillion.io site, but keeps the game window above the
keyboard so everything stays visible.

## What it changes

While a full keyboard is open:

- The game fits into the space above the keyboard instead of sliding off screen.
- The category card shrinks to just the question (24px) at the top.
- Puffer Party: the top bar is hidden, and players, name plates and the puffer
  shrink so seats don't overlap.
- The bottom banner ad is hidden; it comes back when the keyboard closes.

Links that leave Krillion (ads, merch, Instagram) open in Safari.
Everything else, including accounts, rooms and ads, is the real site.

## Build and run

Requires Xcode 26.3 or later.

1. Open `KrillionApp.xcodeproj`.
2. **Signing & Capabilities** → pick your team (a free Personal Team works).
   If signing fails, change the Bundle Identifier to something unique.
3. Pick your iPhone or a simulator and press **⌘R**.

With a free Apple account the app expires after 7 days on a device; run it
again from Xcode to renew.

## How it works

`KrillionApp/GameViewController.swift`

- A `WKWebView` pinned to `view.keyboardLayoutGuide`, so the web view itself
  shrinks to the space above the keyboard. Krillion sees a shorter screen and
  lays the game out to fit.
- An injected stylesheet turns off Krillion's own slide-up and adds the compact
  "typing" layout, switched on by a class the app sets on `<html>` when a full
  keyboard appears.

## Safari version

No app install needed: the same fix as a free Safari userscript lives in
[krillion-keyboard-fix](https://github.com/alanqiao6/krillion-keyboard-fix).

## Not affiliated

A fan project, not made by or affiliated with Krillion. It only changes how
the page looks and never reads or sends game data.
