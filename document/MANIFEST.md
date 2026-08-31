# manifest.toml

The normative text is [`SPEC.md`](SPEC.md). This document is the field reference and the parser's contract, and where the two disagree, `SPEC.md` wins.

`manifest.toml` is what makes a directory a package. It says which open-package the package is written for, what the package is, and what it can run.

```toml
# The specification is `open-package spec`

[open-package]
version = "1.0.0"

[package]
name = "sample-package"
version = "1.2.0"
description = "What this package is good for, in one sentence"
requires = ["python3", "sh"]

[command]
fetch = "sh source/fetch-dependency.sh"
build = "python3 source/build.py"
verify = "sh source/verify.sh"
```

## `[open-package]`

| Key | | What it says |
|---|---|---|
| `version` | **required** | The open-package this package is written for |

Write the least version whose behaviour the package needs, not the version of the runner that wrote the file. Section 4 of `SPEC.md` says which runners then speak for the package.

## `[package]`

| Key | | What it says |
|---|---|---|
| `name` | **required** | What the package calls itself, in one line. Not an identifier: which package this is, is the directory it is in, so nothing has to match |
| `version` | **required** | The package version. Raised when behaviour changes, not for presentation-only edits |
| `description` | optional | One sentence, shown above the command list |
| `requires` | optional | Executables the package's commands need. `check` looks for each on `PATH` and warns when one is absent |

`requires` names executables. Not languages, not versions. `check` only answers whether the name is on `PATH`. Anything finer belongs to a command the package writes, since that can actually test it.

## `[command]`

```
<name> = "the command to run from the package root"
```

The runner executes it through `sh -c`, and the working directory is always the package root. Arguments given after the command name are appended:

```
open-package build a.md -o b.html
  → cd <package root> && sh -c 'python3 source/build.py "$@"' build a.md -o b.html
```

An argument containing a space stays one argument. The command's exit code becomes the runner's.

Appending works for a line that is one invocation. For a pipeline or a sequence the end of the line is not where arguments go:

```toml
build = "python3 source/build.py | tee build.log"   # appended, so they reach tee
```

So a line that writes `"$@"` itself is left alone, and decides:

```toml
build = "python3 source/build.py \"$@\" | tee build.log"
```

The rule is one sentence: **if the line contains `$@`, the runner appends nothing.** A command that should ignore arguments entirely can say so the same way, with `: \"$@\"; …`.

A body that runs nothing, whether spaces, tabs or an escaped newline, is an error and not a warning.

Two kinds of name are not reached by the short form: those the runner answers itself, and anything beginning with `-`. Neither is lost: `run <name>` reaches any name a manifest states (`SPEC.md` rule 3.5).

## What a command does

There is no `[help]` table. `open-package` with no arguments lists each name and the line it runs, which is what will actually happen:

```
COMMANDS
    fetch     sh source/fetch-dependency.sh
    build     python3 source/build.py
```

That listing is the command itself, so it cannot describe the command wrongly. `README.md` is where a package describes itself at length. A name carries no meaning the manifest has not written down, since `SPEC.md` fixes none of them.

## The environment

There is no `[env]` table. A command inherits the caller's environment untouched:

```
SAMPLE_MIRROR=https://mirror.internal open-package fetch
```

Defaults belong to the script that reads the value. A package that looks at a variable names it in its `README.md`.

## What the parser reads

Not all of TOML, but a subset, refused explicitly rather than half-understood.

Read:

- `[table]` headers, one level deep
- `key = "string"`, with the escapes `\n`, `\t`, `\"`, `\\`
- `key = 42`, `key = true`
- `key = ["one", "two"]`
- `#` comments, whole-line or after a value, and blank lines

Not read: multi-line strings, inline tables, arrays of tables (`[[command]]`), nested tables (`[command.nested]`), dates, unquoted values, quoted names (`["command"]`), a key written before any `[table]` header, and dotted keys (`open-package.version = "1.0.0"`, where the `[table]` header is what to write). A dotted key is a second way to write a table, and two ways to say one thing is what this subset exists to avoid. A name is written plainly or not at all: letters, digits, `_` and `-`. A duplicate key is refused. Every refusal names the line, including a refusal raised after parsing.

Each of those is refused rather than merely unread, the same as with values. Taking a shape for some other shape is worse than turning it away. An array of tables that arrives as a table nobody looks up takes its commands with it, and the package runs on without them.

A field's type is part of its contract. Every field above is a string except `requires`, which is an array of strings. A value written as anything else is refused rather than rendered, so `version = 1` is not `"1"`. Otherwise the unquoted values the scanner just refused would walk back in through the integer and boolean syntax, and the one that matters most is the compatibility axis.

A `#` outside a string starts a comment, so a trailing note is safe:

```toml
version = "1.0.0"                # this is a comment
description = "colour #ff0000"   # and this hash is part of the value
```
