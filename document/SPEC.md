# The open-package specification

**open-package 1.0.0.** This document is normative. The runner carries a summary of it and prints that with `open-package spec`. If the two disagree, this one is right.

Rules come at three strengths. **Required** means a directory that breaks it is not an open-package. **Expected** means there are real exceptions, and a person can look at one and decide to leave it alone. **Allowed** covers the rest. Anything this document does not mention is free.

`check` reports a broken requirement as an error and a departure from what is expected as a warning. It cannot see most of what is written here. Passing `check` does not mean the package conforms.

## 1. Scope

An open-package is a directory that states what it is, carries its own material, and says what it can run. That statement is written the same way whatever is inside, so you can ask a package what it offers instead of opening it up.

The package's material, its documents and its composition all travel inside it.

The specification is neutral about two things.

- Language. A manifest never says what a package is written in. It says what has to be on the machine (`requires`) and what can be run (`[command]`).
- Consumer. The specification does not ask who reads a package. `README.md` and `document/` are prose for people, and the same prose read by an agent is a procedure.

## 2. Layout

```
<package>/
  manifest.toml   composition
  README.md       what this package is and what it is good for
  source/         the material of what the package does
  document/       what the package says
```

1. A package has `manifest.toml`. **Required.** It is the whole of what makes a directory a package.
2. A package has `README.md`. **Expected.** Without it the package does not describe itself.
3. A package puts its material in `source/` and what it says in `document/`, and keeps the top level to those four, `LICENSE*`, and entries beginning with a dot. **Expected.**

The directory name can be anything. A package is identified by where it sits (section 6), so the manifest does not repeat it.

Two branches. A file goes in `source/` if it is material the package works with, and in `document/` if it is something the package says. What decides it is the file's role. The format does not matter, and neither does who reads it.

| File | Branch and why |
|---|---|
| JavaScript served to a browser | `source/`. A command bundles it into the output |
| A syntax reference for the package's input format | `document/`. It says what the package accepts |
| A procedure someone or something follows by hand | `document/`. The package is speaking, not working |
| A template a command fills in | `source/`. The output is made of it |

Some files are both: prose a person reads, and input a command runs on. Put it in `document/` if the package would still say it with no command reading it. Otherwise it exists to be consumed, and it belongs in `source/`.

## 3. manifest.toml

The field-by-field reference is [`MANIFEST.md`](MANIFEST.md). What the specification itself asks for:

1. `[open-package] version` is there, and is a version this runner can speak for. **Required.** See section 4.
2. `[package] name` and `version` are there. **Required.** Neither is an identifier. A package is found by where it is, so `name` is just what the package calls itself, and it can read like a title.
3. `manifest.toml` is committed with the package. **Required.** Without it the package arrives with no statement of what it is.
4. A `[command]` body runs something. **Required.** A body that runs nothing exits 0, and the command reports success without having run.
5. A `[command]` name is one the runner has not already spent, which means not a built-in and not a name beginning with `-`. **Expected.** `run <name>` still reaches it. You lose the short form, not the command.
6. Every value is written as the type `MANIFEST.md` gives it. **Required.** A runner refuses a value of another type rather than rendering it, so `version = 1` is not `"1"`.

`requires` is not among them. Whether the executables it names are on this machine is a fact about the machine, so `check` only warns. Copying a package somewhere plainer does not make it malformed.

There is no field for what a command does, and none for the environment. The listing already shows the line each name runs, and that line is the command, so it cannot describe it wrongly. A summary beside it could. As for the environment, the manifest is committed and travels with the package, so anything in it is published. Values that differ per machine do not belong there, and secrets certainly do not.

## 4. Versions

There is one compatibility axis, `[open-package] version`. There is no separate specification number.

1. A package declares the open-package it is written for. **Required.** The value is the least version whose behaviour the package needs, not the version of the runner that happened to mint it. Otherwise a runner's own patch release turns into a compatibility event.
2. A runner refuses to run anything for a package it cannot speak for. **Required.** It speaks for a package when the majors match and its own version is at least what the package asks for.
3. `[package] version` goes up when behaviour changes, and stays put for presentation-only edits. **Expected.** No runner can tell whether behaviour changed.

A newer 1.x runner reads a package written for 1.0. A package asking for 1.4 is refused by a 1.2 runner. Across a major it is refused in both directions, since that is a different format. A runner that read a manifest as far as it happened to make sense would quietly do the wrong thing, so it runs nothing at all instead.

A receiving side records `[package] version` when it takes a copy. What it does with the number after that is its own business (rule 7.3). There is no registry here.

## 5. Commands

### Built-in

The runner answers these itself:

| Name | Needs a package? | Meaning |
|---|---|---|
| `run` | yes | Run one of the package's own commands by name |
| `check` | yes | Inspect the layout and the manifest |
| `spec` | no | Print the specification summary |
| `new` | no | Create a package |

`spec` and `new` answer without a package around them. That is why bootstrapping is one download. `help` is claimed too, by the argument parser.

### The package's own

Any name not answered by the runner is looked up in `[command]` and run from the package root through `sh`. Its exit code is the runner's exit code.

`run <name>` is the same call written the long way, and reaches every name including the ones the runner answers first. The short form is what anyone writes.

A name means nothing beyond the line beside it. What a package calls its commands is up to the package.

1. A command answers with its exit code, not with prose for a person to judge. **Expected.** Write down what success looks like ("about 3.4 MB, and the canvas shows a list") and a person has to read and rule on it every time.

Arguments given after the command name reach the command:

1. If the command line contains `$@`, the runner passes it unchanged and lets the line place the arguments itself.
2. Otherwise the runner appends them.

Appending works for a single invocation. It breaks a pipeline, where the end of the line is not where arguments go. The test is textual, so a `$@` meant literally will fool it.

## 6. Which package a command is about

The one the caller is standing in. The search walks up from the working directory until it finds a `manifest.toml`, the way a package manager does. Nothing else is consulted: no environment variable, no registry, no configuration file.

Packages can nest, and the same rule covers it. `source/` may hold a whole package of another kind, and standing inside that one addresses it, since its `manifest.toml` is the nearest. The outer package reaches the inner one by relative path from the outer root. Each is judged on its own `[open-package] version`.

## 7. Rules

**7.1. Reference inside the package by relative path only.** Assume nothing about the working directory, the calling path, or the install location. The runner always executes commands from the package root, so a manifest writes package-root-relative paths. A script reaching for a file beside it resolves from its own location (`Path(__file__).parent` in Python, `dirname "$0"` in shell).

**7.2. Never point outside.** Stand a shared document outside the package and reference it, and the link breaks wherever the package is copied. Repeat it in every package that needs it. Duplication is the price.

> This is about the filesystem. A command that fetches from the network is allowed, and the package is choosing a cost by doing it. A fetch can stop working while the package itself never changed.

**7.3. A package does not know where it will be placed.** The package says what it is good for. Where it goes in a system, and when that system should reach for it, is the receiving side's knowledge.

**7.4. What the package offers is already runnable.** The receiving side is never asked to build it. For a compiled language that means carrying the build product, and `requires` names things that run it, not things that compile it.

> Interpreted files are not exempt. A `.py` or `.sh` is itself the thing that runs. The test is whether it runs on something you can name in `requires`.

## 8. The runner

Every package is read by the same program, and it lives on the machine. It reads the manifest, refuses what it cannot speak for, runs commands from the package root, and answers the built-ins. Nothing about any one package goes in, which is how one binary serves them all.

The reference runner is a macOS universal binary built from `source/open-package`. It is published as a release asset rather than committed, which is rule 7.4 applied to the runner itself.

A package runs where its runner runs. The reference runner is a native binary, so today that means macOS. It is a limit of the runner, not of the format.

## 9. Changing the specification

Adding something is a minor bump. Packages that want it declare the version that has it, and older packages keep working. Changing or removing something is a major bump, and majors do not read each other. Otherwise fallbacks for the old shape pile up until there are two specifications.

The move is:

1. Update this document, and `Specification.summary` in the runner
2. Raise `Environment.version`, then `open-package build`
3. Publish the new runner
4. Raise `[open-package] version` in the packages that need the change

On a major bump every package moves.
