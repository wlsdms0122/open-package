# open-package

A package format that is neutral about language and consumer. This repository is the specification, and the runner every package is read by.

A directory becomes an open-package by stating what it is in `manifest.toml`. It can hold shell scripts, a compiled tool, prose, or a whole Swift package. Run `open-package` inside it and it tells you what it can run, and the line each name runs.

This directory is itself an open-package, and it passes its own `check`.

The specification is [`document/SPEC.md`](document/SPEC.md), and the field-by-field reference is [`document/MANIFEST.md`](document/MANIFEST.md). `open-package spec` prints a summary of the first from inside any package, and `open-package --help` explains the runner.

## Why this exists

### Prose that has to be re-typed is not a procedure

The usual way to hand over a piece of work is a document: here is what it does, here is how to install it, here is how to check it worked. Every one of those sentences is an instruction the receiving side has to read, translate and re-type, and every re-typing is a place to get it wrong. Worse, the document goes stale silently. Nothing fails when the install steps stop being true.

open-package moves those sentences into `[command]`, where they are executable. A paragraph about how to check the thing worked becomes a command that inspects and answers with its exit code, instead of "you should see roughly 3.4 MB and a list in the canvas". The reader stops having to judge, and the package does it.

### Knowledge and tools should travel together

A tool without its documents is a black box, and documents without their tool cannot be acted on. The two get separated because they are usually stored by *kind*, code in one repository and documents in another, rather than by *what they are for*.

An open-package holds both, and its two branches are exactly that split:

| Branch | What lives there |
|---|---|
| `source/` | the material of what the package does |
| `document/` | what the package says, about itself and about its subject |

They are split, but they sit in one directory and move together. Where they end up afterwards is the receiving side's business. What matters here is that they arrive together.

### Neutral about the consumer

This is where open-package parts from the SKILL.md family. Those formats assume an LLM in the format itself: they are behaviour instructions, written as "when you get a request like this, do this".

open-package drops the assumption and puts nothing in its place. `README.md` and `document/` are prose for people, and the same prose read by an agent is a procedure. When the next kind of reader shows up there is nothing to re-invent.

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
    Runner/             everything the runner can do, and what it answers with
  Service/              the subjects the specification defines
    Package/            finding, inspecting and creating one
    Manifest/           what a package declares, and loading it
  Module/
    TOML/               the subset a manifest is written in
    Environment.swift   what this binary is, and what it can speak for
  Core/
    Version.swift       the versions everything here is compared by

Sources/OpenPackageCLI/
  CLI.swift             the entry point, the manual, and the one fork
  Passthrough.swift     a word the package owns, run before the parser sees it
  Refusal.swift         a library error, with the way out only this surface can name
  UsageWriter.swift     the screen for someone who does not know what is inside
  Command/              one file per built-in, and the names this surface has taken
  Support/              where this process is, and the two streams it answers on
```

The path tells you which layer a type belongs to. `Feature/` is the library's whole public face, one type per thing the runner does. The ones that act on an existing package find it themselves and refuse what this runner cannot speak for, so no entry point skips either step. `Service/` holds what the format is made of, and is almost entirely internal. `Module/` holds what the format is not about: a TOML reader owes nothing to open-package, and which binary is running is a fact about the process. `Core/` is what every layer compares itself against.

Subjects sit side by side rather than nested. A manifest is not part of a package's layout, and TOML is not part of a manifest. A concept with its own vocabulary keeps it in its own `Model/`, behaviour sits at the top of its concept, and an error lives where it is raised. That last one is why the version gate and every way a manifest can fail to be read share a file.

The command line is not layered. That whole target is already this package's outermost layer, and dividing it again would repeat the same four words one level down over files that are all surface. `Support/` holds what the surface stands on, never what it does. Without that line it turns into a drawer.

`Tests/OpenPackageTests` is grouped by subject rather than by layer. The unit suites cover what the runner reads and judges. The command-line suite drives the real binary against real directories, since what this specification promises is about a binary sitting in a directory.

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
