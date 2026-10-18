# open-package

A package format that is neutral about language and consumer. This repository is the specification, and the runner every package is read by.

A directory becomes an open-package by stating what it is in `manifest.toml`, under an `[open-package]` table. It can hold shell scripts, a compiled tool, prose, or a whole Swift package. Run `open-package` inside it and it tells you what it can run, and the line each name runs.

That listing takes `--json`, and so does `check`, which answers the same thing in one line for a program rather than for a person. The specification says a package does not ask who reads it, and this is the runner keeping that promise on its own surface.

This directory is itself an open-package, and it passes its own `check`.

The specification is [`document/SPEC.md`](document/SPEC.md), and the field-by-field reference is [`document/MANIFEST.md`](document/MANIFEST.md). `open-package spec` prints a summary of the first from inside any package, and `open-package --help` explains the runner.

## Why this exists

### Prose that has to be re-typed is not a procedure

The usual way to hand over a piece of work is a document: here is what it does, here is how to install it, here is how to check it worked. Every one of those sentences is an instruction the receiving side has to read, translate and re-type, and every re-typing is a place to get it wrong. Worse, the document goes stale silently. Nothing fails when the install steps stop being true.

open-package moves those sentences into `[command]`, where they are executable. A paragraph about how to check the thing worked becomes a command that inspects and answers with its exit code, instead of "you should see roughly 3.4 MB and a list in the canvas". The reader stops having to judge, and the package does it.

### The manifest is the whole specification

A directory is an open-package because its `manifest.toml` opens an `[open-package]` table, and for no other reason. That one file says the directory is a package and says everything needed to use it. The runner finds a package by that table, so a `manifest.toml` belonging to some other format is passed by.

Nothing else is asked of the directory. A tool, its documents, a whole Swift package or a folder of markdown are arranged however suits them, and an existing project becomes a package by gaining a manifest rather than by being rearranged. What travels together is whatever sits beside the manifest.

### Neutral about the consumer

This is where open-package parts from the SKILL.md family. Those formats assume an LLM in the format itself: they are behaviour instructions, written as "when you get a request like this, do this".

open-package drops the assumption and puts nothing in its place. What a package writes for people, an agent reads as a procedure. When the next kind of reader shows up there is nothing to re-invent.

Language works the same way. A Python builder, a Swift binary and a folder of markdown are all packaged alike, and the same program reads all three.

## Install

```
curl -fsSL https://raw.githubusercontent.com/wlsdms0122/open-package/main/source/install.sh | sh
```

Installs the runner into `/usr/local/bin`. Two things change that:

| Setting | What it changes |
|---|---|
| `--prefix <dir>` or `OPEN_PACKAGE_PREFIX` | Where to install. Defaults to `/usr/local/bin` |
| `OPEN_PACKAGE_RUNNER` | Where to fetch from. A mirror, or a `file://` path |

That is all `install.sh` does. Creating a package is the runner's own job:

```
open-package new my-package
```

## What is inside this repository

| Path | Role |
|---|---|
| `document/SPEC.md` | The normative specification |
| `document/MANIFEST.md` | Field reference, and the TOML subset the parser reads |
| `source/open-package/` | The runner, a Swift package |
| `source/build.sh` | Builds the runner and leaves it at `.build/open-package` |
| `source/install.sh` | Puts a released runner on a machine |

The Swift package is a library and a command line over it:

```
Sources/OpenPackage/
  Feature/
    Runner/             what the library does, one type each, and what each answers with
  Service/              the subjects the specification defines
    Package/            finding the package around a place
    Manifest/           what a package declares, and loading it
  Module/
    TOML/               the subset a manifest is written in
    Environment.swift   what this binary is, and which packages it supports
  Core/
    Version.swift       the versions everything here is compared by

Sources/OpenPackageCLI/
  CLI.swift             the entry point, the manual, and the one fork
  Passthrough.swift     a call to the package's own commands, run before the parser sees it
  Call.swift            where the runner's words end and the command's begin
  CallError.swift       what is wrong with a call, as this surface sees it
  Refusal.swift         a library error, with the way out only this surface can name
  UsageWriter.swift     the screen for someone who does not know what is inside
  Output/               which of the two forms the output takes, the two streams it goes
                        on, the envelope every JSON line carries, and one record per thing
                        the runner prints
  Command/              the names this surface has taken, one file per built-in
  Support/              where this process is
```

A built-in either states its result in both forms at once, or, like `run`, passes the package's own output through. `BuiltinCommand` maps each name the runner has taken to the command that answers it in one switch.

`Feature/` is the library's whole public face. A runner that acts on a package finds it and loads its manifest itself, and loading refuses what this runner does not support, so no entry point skips either step. `Service/` holds what the format is made of and is internal. `Module/` holds what the format is not about: the TOML reader and which binary is running. `Core/` is what every layer compares against.

A concept keeps its vocabulary in its own `Model/`, and an error lives where it is raised. The command line is one layer, since the whole target is already the outermost one. `Support/` holds what the surface stands on.

`Tests/OpenPackageTests` is grouped by subject. The unit suites cover what the runner reads and judges, and the command-line suite drives the real binary against real directories.

## Development

```
open-package build
open-package test
open-package verify
```

`open-package` with no arguments lists what each of those runs.

The runner is not committed, so a fresh clone reaches its own commands one of two ways: install a released runner, or build one and call it by path.

```
sh source/build.sh          # writes .build/open-package
.build/open-package test
```

Either way `open-package build` leaves its result at `.build/open-package`. `.build/` is ignored by git, since it is what this repository produces rather than what it holds.

Releasing is `open-package build`, then attaching `.build/open-package` to a GitHub release named after the **runner** version, under exactly that filename. `install.sh` fetches `releases/latest/download/open-package`, so a renamed asset is a 404.
