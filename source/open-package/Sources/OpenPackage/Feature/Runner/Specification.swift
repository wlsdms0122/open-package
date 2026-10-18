//
//  Specification.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

/// A summary; `document/SPEC.md` is normative and wins where they disagree.
public enum Specification {
    public static var summary: String {
        """
        open-package \(Environment.version), a package specification that is neutral about language and consumer

          A directory is an open-package when it holds a manifest.toml that opens an [open-package] table. That file is the whole specification of a package: it says the directory is one, and it says everything needed to use it. How the rest of the directory is arranged is up to the package.

        WHAT IT IS FOR
            Like npm, gem or crate: whatever is inside, the surface seen from outside is the same. Run `open-package` inside one and it lists what the package can run, and the line each name runs. A receiving side learns what a package offers without opening it. The specification does not ask whether the consumer is a person or a machine. A package's prose is for people, and the same prose read by an agent is a procedure.

        MANIFEST
            [open-package] version     The open-package this package is written for. The table is
                                       what makes the file a package's manifest. The runner you
                                       invoke is the one that judges, and a runner that does not
                                       support the version refuses to run anything
            [package]      name version description requires. Which package this is, is the
                           directory it is in, so the manifest does not name one
            [command]      <name> = "command to run from the package root"

            Values are strings, integers, booleans and single-line arrays, and a value must be written as the type it is declared as. Arguments given after a command name are appended, unless the line contains $@, in which case it places them itself. That is what a pipeline or a sequence needs. A name the runner answers first (run, check, spec, new, help), or one starting with -, is not reached by the short form. `run <name>` reaches it, and `run -- <name>` reaches one starting with -.

        PACKAGE COMMANDS
            No command name is fixed. What a package calls its commands is up to the package. Names like build, test and verify are what packages tend to reach for, not meanings the specification has settled. A command answers with its exit code rather than with prose for a person to judge. Write down what success looks like and a person has to read and rule on it every time.

        BUILT-IN COMMANDS
            Answered by the runner itself, in any package. run and check are about a package, so they need one around them. spec and new answer anywhere, so bootstrapping is one download.

            run      Run one of the package's own commands by name
            check    Inspect the manifest
            spec     Print the specification
            new      Create a package

        RULES
            1. Reference inside the package by relative path only. Wherever it is placed, and from wherever it is called, the result is the same (commands always run from the package root)
            2. Never point outside. One package is the whole of itself
            3. A package does not know where it will be placed. What it is good for is its own to say; where it goes and when to reach for it are the receiving side's
            4. What the package offers is already runnable. The receiving side is never asked to build it, so a compiled language ships its build product
        """
    }
}
