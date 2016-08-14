# ComputerCraft Package Administration Worker

[![GitHub release](https://img.shields.io/github/release/cc-paw/cc-paw.svg)](https://github.com/cc-paw/cc-paw/releases/latest)
[![GitHub downloads](https://img.shields.io/github/downloads/cc-paw/cc-paw/latest/total.svg?maxAge=3000)](https://github.com/cc-paw/cc-paw/releases/latest)
[![GitHub issues](https://img.shields.io/github/issues-raw/cc-paw/cc-paw.svg?maxAge=3000)](https://github.com/cc-paw/cc-paw/issues)
[![GitHub license](https://img.shields.io/github/license/cc-paw/cc-paw.svg?maxAge=2592000)](https://github.com/cc-paw/cc-paw/blob/master/LICENSE.txt)

A package manager for ComputerCraft.

CC-PAW aims to provide an easy-to-use method for installing, upgrading, and
removing software on ComputerCraft computers.

This repository contains the source for CC-PAW itself, and releases of it and
its dependencies.

## Installation

Run `pastebin run VmqguQeA` on a ComputerCraft device to install CC-PAW.

You must have the HTTP API enabled, and have `github.io` or `cc-paw.github.io`
on your whitelist. (These options are enabled by default.)

(You can also find a disk with an installer on it if you install and enable the
 resource pack. You can find this under Releases.)

## Usage

Run `man cc-paw` at any time to view the manual for CC-PAW. It works somewhat
similar to `apt-get`, so it should be familiar to users of Debian-based systems.

## Upgrading

Run `cc-paw update` and then `cc-paw upgrade` at any time to upgrade CC-PAW
itself, as well as any installed packages.

## Development

For now, see the `example-package-info.lua` file in this repository, (and the
releases here and pacakges repository), for examples. In the future, a guide
will be written on the subject.
