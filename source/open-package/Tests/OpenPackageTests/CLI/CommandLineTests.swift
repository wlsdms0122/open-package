//
//  CommandLineTests.swift
//  OpenPackageTests
//
//  Created by JSilver on 8/30/26.
//

import Foundation
import Testing

@testable import OpenPackage
@testable import OpenPackageCLI

/// The contract a package sees: a real binary, real directories, real exit codes. The unit
/// suites cover what the runner reads and judges; this covers what it does.
@Suite("CommandLine Tests")
struct CommandLineTests {
    // MARK: - Property
    private let workspace = Workspace()
    private let cli = CLIRunner()

    // MARK: - Initializer
    // MARK: - Test
    @Test("a well formed package passes check")
    func passesCheck() throws {
        // Given
        let package = try bundled("good", manifest: .manifest(named: "good"))

        // When
        let result = run(package, "check")

        // Then
        #expect(result.status == 0, "\(result.output)")
    }

    @Test("the version line names the runner")
    func reportsVersion() throws {
        // Given
        let package = try bundled("good", manifest: .manifest(named: "good"))

        // When
        let result = run(package, "--version")

        // Then
        #expect(result.standardOutput.contains("\(Environment.version)"), "\(result.output)")
    }

    @Test("no argument lists what the package declares, and what each name runs")
    func listsDeclaredCommands() throws {
        // Given
        let package = try bundled("good", manifest: .manifest(
            named: "good",
            commands: "greet = \"echo hello\"\nverify = \"true\""
        ))

        // When
        let result = run(package)

        // Then
        #expect(result.standardOutput.contains("greet"), "\(result.output)")
        #expect(result.standardOutput.contains("echo hello"), "\(result.output)")
        #expect(result.standardOutput.contains(BuiltinCommand.new.rawValue), "\(result.output)")
    }

    @Test("--json answers the listing in the manifest's own words")
    func answersTheListingAsJSON() throws {
        // Given
        // The package asks for this major's floor rather than the running version, so that
        // the two version keys hold different strings. Written the same, a record that put
        // the runner's version in both would pass without either being read.
        let required = "\(Environment.version.major).0.0"
        let package = try bundled("good", manifest: .manifest(
            named: "good",
            requiring: required,
            commands: "greet = \"echo hello\"\ncheck = \"true\""
        ))

        // When
        let result = run(package, "--json")

        // Then
        let record = try decode(result)

        #expect(result.status == 0, "\(result.output)")
        #expect(record["runner"] as? String == "\(Environment.version)", "\(result.output)")
        #expect((record["open-package"] as? [String: Any])?["version"] as? String
            == required, "\(result.output)")
        #expect((record["package"] as? [String: Any])?["name"] as? String == "good", "\(result.output)")
        #expect(record["diagnosis"] == nil, "only check looks, so nothing else may report a diagnosis")

        // And a name this runner answers first is marked, since a caller that built
        // 'open-package check' from this listing would reach the runner instead.
        let commands = try #require(record["command"] as? [[String: Any]])

        #expect(commands.first { $0["name"] as? String == "greet" }?["run"] as? String == "echo hello")
        #expect(commands.first { $0["name"] as? String == "greet" }?["conflict"] == nil)
        // Spelled out rather than read back from the enum. Taken from the type, a rename of
        // the case would carry the test with it and the contract would break unwatched.
        #expect(commands.first { $0["name"] as? String == "check" }?["conflict"] as? String
            == "reserved", "\(result.output)")
    }

    @Test("check --json carries the findings, and the exit code still decides")
    func answersCheckAsJSON() throws {
        // Given a package whose layout departs from the shape, so there is something to report.
        let package = try bundled("sparse", manifest: .manifest(named: "sparse"))
        try FileManager.default.removeItem(at: package.appendingPathComponent("README.md"))

        // When
        let result = run(package, "check", "--json")

        // Then
        let diagnosis = try #require(try decode(result)["diagnosis"] as? [String: Any])

        #expect(result.status == 0, "a warning is not a failure")
        #expect((diagnosis["errors"] as? [String])?.isEmpty == true, "\(result.output)")
        #expect((diagnosis["warnings"] as? [String])?.isEmpty == false, "\(result.output)")
    }

    @Test("a malformed package answers as JSON and still leaves with a failure")
    func failsLoudlyInJSON() throws {
        // Given a manifest the specification requires more of.
        let package = try bundled("nameless", manifest: """
            [open-package]
            version = "\(Environment.version)"

            [package]
            version = "0.1.0"

            [command]
            verify = "true"
            """)

        // When
        let result = run(package, "check", "--json")

        // Then the answer is on the stream a caller reads, even though the package is not valid.
        let diagnosis = try #require(try decode(result)["diagnosis"] as? [String: Any])

        #expect(result.status != 0, "\(result.output)")
        #expect((diagnosis["errors"] as? [String])?.isEmpty == false, "\(result.output)")
    }

    @Test("a runner standing on its own says which runner, and nothing about a package")
    func answersWithoutAPackageAsJSON() throws {
        // Given
        let lone = try loneRunner()

        // When
        let result = cli.run(["--json"], from: workspace.root, runner: lone)

        // Then absent rather than empty: a caller reading an empty name cannot tell whether
        // the package said nothing or there was no package to ask.
        let record = try decode(result)

        #expect(record["runner"] as? String == "\(Environment.version)", "\(result.output)")
        #expect(record["package"] == nil, "\(result.output)")
        #expect(record["command"] == nil, "\(result.output)")
    }

    @Test("every built-in that answers honours --json, and run leaves it to the command")
    func honoursJSONOnEveryBuiltin() throws {
        // Given
        let package = try bundled("good", manifest: .manifest(
            named: "good",
            commands: "echo = \"echo\""
        ))
        let destination = workspace.path("created-as-json")

        // When
        let specification = run(package, "spec", "--json")
        let created = run(package, "new", destination.path, "--json")
        let carried = run(package, "run", "echo", "--json")

        // Then a word the parser hands to all of them is honoured by all of them.
        #expect(try decode(specification)["specification"] as? String != nil, "\(specification.output)")
        #expect(try decode(created)["created"] as? String == destination.path, "\(created.output)")

        // And run is the exception twice over: after the name the word is the package's
        // argument, and in front of the name it is refused rather than taken and dropped.
        let refused = run(package, "--json", "run", "echo")

        #expect(carried.standardOutput == "--json\n", "\(carried.output)")
        #expect(refused.status != 0, "\(refused.output)")
        // Parsed rather than searched for words. A refusal printed as prose would contain
        // the same sentence and pass, which is the hole this shape exists to close.
        #expect(try decode(refused)["reason"] as? String != nil, "\(refused.output)")
    }

    @Test("the short form answers --json the way the long one does")
    func refusesTheShortFormInJSON() throws {
        // Given
        let package = try bundled("good", manifest: .manifest(
            named: "good",
            commands: "greet = \"echo hello\""
        ))

        // When the word comes before the name, whichever way the call is spelled.
        let short = run(package, "--json", "greet")
        let long = run(package, "--json", "run", "greet")
        let between = run(package, "run", "--json", "greet")
        let unknown = run(package, "--json", "bogus")

        // And a name the runner would answer first, which `run` exists to reach past. Read
        // with the same question as the short form, this one was the package's command with
        // the word taken and nothing done about it.
        let reserved = run(package, "--json", "run", "check")

        // Then all four refuse alike. Written apart, the spellings answered differently:
        // one refused, one handed the word to the package, one died on the parser.
        for result in [short, long, between, reserved] {
            #expect(result.status != 0, "\(result.output)")
            #expect(try decode(result)["reason"] as? String != nil, "\(result.output)")
        }

        // And a name that is not there is answered with that, not with a sentence about
        // JSON. Read for existence alone, this passed while saying the wrong thing.
        #expect(try #require(decode(unknown)["reason"] as? String).contains("bogus"),
            "\(unknown.output)")

        // A call that could not be made as written leaves at 64; one the package refused
        // leaves at 1. The two are different answers and say so.
        #expect(short.status == 64, "\(short.output)")
        #expect(unknown.status == 1, "\(unknown.output)")
    }

    @Test("the way out the listing names for a reserved name actually reaches it")
    func reachesANameTheShortFormCannot() throws {
        // Given a package that declares a name the runner reads as an option.
        let package = try bundled("dashed", manifest: .manifest(
            named: "dashed",
            commands: "-x = \"echo reached\""
        ))

        // When
        let listing = run(package)
        let terminated = run(package, "run", "--", "-x")
        let short = run(package, "--", "-x")

        // Then the advice beside the row is advice that works. Read as the runner's own by
        // its shape, the name was taken on its way past and the one documented way in was
        // the one way that could not be taken.
        #expect(listing.standardOutput.contains("(run -- -x)"), "\(listing.output)")
        #expect(terminated.standardOutput == "reached\n", "\(terminated.output)")
        #expect(short.standardOutput == "reached\n", "\(short.output)")
    }

    @Test("a call with no name in it is still the package's call, and answers alike")
    func answersAnUnnamedCall() throws {
        // Given
        let package = try bundled("named", manifest: .manifest(named: "named"))

        // When
        let before = run(package, "--json", "run")
        let after = run(package, "run", "--json")
        let plain = run(package, "run")

        // Then a name short of a call is a call, not a word the parser should write a screen
        // about. One name's difference used to decide whether the answer had a shape.
        // Read as "not zero", the two shapes left at different codes for the same sentence.
        for result in [before, after] {
            #expect(result.status == 64, "\(result.output)")
            #expect(try #require(decode(result)["reason"] as? String).contains("needs the name"),
                "\(result.output)")
        }

        #expect(plain.status == 64, "\(plain.output)")
        #expect(plain.output.contains("needs the name"), "\(plain.output)")
    }

    @Test("run's own manual is reachable the way every manual is")
    func leavesTheManualToTheParser() throws {
        // Given a package, so that the fork has something it could have dispatched the call for.
        let package = try bundled("manual", manifest: .manifest(named: "manual"))

        // When
        let long = run(package, "run", "--help")
        let short = run(package, "run", "-h")

        // Then. Read as a name, `--help` is a command no package declares, and the one way
        // to this manual answers that there is no such command.
        #expect(long.standardOutput.contains("OVERVIEW"), "\(long.output)")
        #expect(short.standardOutput.contains("OVERVIEW"), "\(short.output)")
    }

    @Test("a terminator after run is a call that names nothing, not the parser's business")
    func answersATerminatedCallWithNoName() throws {
        // Given
        let package = try bundled("terminated-unnamed", manifest: .manifest(named: "terminated"))

        // When
        let asked = run(package, "--json", "run", "--")
        let plain = run(package, "run", "--")

        // Then the same answer `run` alone gives. Handed to the parser instead, a caller that
        // asked for JSON reads `Missing expected argument` off the screen.
        #expect(asked.status == 64, "\(asked.output)")
        #expect(try #require(decode(asked)["reason"] as? String).contains("needs the name"),
            "\(asked.output)")
        #expect(plain.status == 64, "\(plain.output)")
        #expect(plain.output.contains("needs the name"), "\(plain.output)")
    }

    @Test("a field the manifest never wrote is absent, arrays included")
    func omitsAnUnwrittenRequires() throws {
        // Given the manifest helper writes no requires.
        let silent = try bundled("requireless", manifest: .manifest(named: "requireless"))
        let spoken = try bundled("requiring", manifest: """
            [open-package]
            version = "\(Environment.version)"

            [package]
            name = "requiring"
            version = "0.1.0"
            requires = ["sh"]

            [command]
            verify = "true"
            """)

        // When
        let quiet = try #require(try decode(run(silent, "--json"))["package"] as? [String: Any])
        let loud = try #require(try decode(run(spoken, "--json"))["package"] as? [String: Any])

        // Then present and empty would leave a caller guessing whether the package requires
        // nothing or never said.
        #expect(quiet["requires"] == nil)
        #expect(loud["requires"] as? [String] == ["sh"])
    }

    @Test("the refusal for a passed-through call names neither spelling")
    func refusesWithoutNamingASpelling() throws {
        // Given
        let package = try bundled("neutral", manifest: """
            [open-package]
            version = "\(Environment.version)"

            [package]
            name = "neutral"
            version = "0.1.0"

            [command]
            greet = "echo hello"
            """)

        // When the short form, which never typed the long one.
        let reason = try #require(try decode(run(package, "--json", "greet"))["reason"] as? String)

        // Then. Quoting `run` here tells a caller about a word it did not write.
        #expect(!reason.contains("'\(BuiltinCommand.run.rawValue)'"), "\(reason)")
    }

    @Test("a call that names nothing outside a package says there is no package")
    func answersAnUnnamedCallOutsideAPackage() throws {
        // Given nowhere in particular. When
        let plain = cli.run([BuiltinCommand.run.rawValue], from: workspace.root)
        let asked = cli.run(["--json", BuiltinCommand.run.rawValue], from: workspace.root)

        // Then the same fact the short form reports, at the same status. Answered as a
        // missing name instead, the advice sends the caller to a listing that is not there.
        #expect(plain.status == 1, "\(plain.output)")
        #expect(plain.output.contains("no open-package here"), "\(plain.output)")
        #expect(asked.status == 1, "\(asked.output)")
        #expect(try #require(decode(asked)["reason"] as? String).contains("no open-package here"),
            "\(asked.output)")
    }

    @Test("the JSON listing says how to reach a name the short form misses")
    func namesTheInvocationInJSON() throws {
        // Given a package whose command names the runner reads as an option.
        let package = try bundled("dashed-json", manifest: """
            [open-package]
            version = "\(Environment.version)"

            [package]
            name = "dashed-json"
            version = "0.1.0"

            [command]
            -x = "echo dashed"
            greet = "echo hello"
            """)

        // When
        let commands = try #require(try decode(run(package, "--json"))["command"] as? [[String: Any]])

        // Then the rule for writing the call stays where the screen reads it from, rather
        // than being rebuilt by everyone who parses this.
        let dashed = try #require(commands.first { $0["name"] as? String == "-x" })
        #expect(dashed["invocation"] as? String == "run -- -x")
        #expect(commands.first { $0["name"] as? String == "greet" }?["invocation"] == nil)
    }

    @Test("a manifest that declares no command says so by leaving the key out")
    func omitsAnUnwrittenCommand() throws {
        // Given a manifest with no [command] table at all.
        let silent = try bundled("commandless", manifest: """
            [open-package]
            version = "\(Environment.version)"

            [package]
            name = "commandless"
            version = "0.1.0"
            """)
        let spoken = try bundled("commanding", manifest: .manifest(
            named: "commanding",
            commands: "greet = \"true\""
        ))

        // When
        let quiet = try decode(run(silent, "--json"))
        let loud = try decode(run(spoken, "--json"))

        // Then the same rule the fields above it follow. Present and empty leaves a caller
        // guessing whether the package declares nothing or was never read.
        #expect(quiet["command"] == nil)
        #expect(try #require(loud["command"] as? [Any]).count == 1)
    }

    @Test("the terminator forgives the shape of a name, not the runner's claim on it")
    func keepsAReservedNameTheRunnersAfterATerminator() throws {
        // Given a package that declares a name the runner answers first.
        let package = try bundled("terminated-reserved", manifest: .manifest(
            named: "terminated-reserved",
            commands: "\(BuiltinCommand.check.rawValue) = \"echo package\""
        ))

        // When
        let short = run(package, "--", BuiltinCommand.check.rawValue)
        let long = run(package, BuiltinCommand.run.rawValue, "--", BuiltinCommand.check.rawValue)

        // Then only `run` says the name is the package's. Read as the package's after a bare
        // terminator, the same two words mean the runner's inspection or the package's
        // command depending on a word that says nothing about either.
        #expect(short.standardOutput != "package\n", "\(short.output)")
        #expect(long.standardOutput == "package\n", "\(long.output)")
    }

    @Test("a caller that asked for JSON reads a parser refusal as JSON too")
    func answersAParserRefusalInJSON() throws {
        // Given
        let package = try bundled("parser-refusal", manifest: .manifest(named: "parser-refusal"))

        // When the parser turns the words away before any built-in runs.
        let missing = run(package, "--json", BuiltinCommand.new.rawValue)
        let unexpected = run(package, "--json", BuiltinCommand.check.rawValue, "bogus")

        // Then the refusal is a line to parse. The parser words its own prose and leaves, so
        // read as one a caller reads `Usage:` off the screen with nothing to match on.
        #expect(missing.status == 64, "\(missing.output)")
        #expect(try #require(decode(missing)["reason"] as? String).contains("Missing expected"),
            "\(missing.output)")
        #expect(unexpected.status == 64, "\(unexpected.output)")
        #expect(try #require(decode(unexpected)["reason"] as? String).contains("bogus"),
            "\(unexpected.output)")
    }

    @Test("the manual and the version stay prose, whatever was asked for")
    func writesTheManualAsProse() throws {
        // Given
        let package = try bundled("manual", manifest: .manifest(named: "manual"))

        // When
        let manual = run(package, "--json", "--help")
        let version = run(package, "--json", "--version")

        // Then neither is a refusal, and neither leaves non-zero.
        #expect(manual.status == 0, "\(manual.output)")
        #expect(manual.standardOutput.contains("OVERVIEW:"), "\(manual.output)")
        #expect(version.status == 0, "\(version.output)")
        #expect(version.standardOutput.contains("\(Environment.version)"), "\(version.output)")
    }

    @Test("a bare terminator names nothing, so it is not a call")
    func readsABareTerminatorAsNoCall() throws {
        // Given
        let package = try bundled("bare", manifest: .manifest(named: "bare"))

        // When
        let result = run(package, "--")

        // Then the listing, not a complaint naming a word nobody typed.
        #expect(result.status == 0, "\(result.output)")
        #expect(result.standardOutput.contains("COMMANDS"), "\(result.output)")
    }

    @Test("a runner word this fork does not know is left to the parser")
    func leavesUnknownRunnerWordsToTheParser() throws {
        // Given a package whose command name would be reached by the short form.
        let package = try bundled("helpful", manifest: .manifest(
            named: "helpful",
            commands: "greet = \"echo hello\""
        ))

        // When
        let help = run(package, "--help", "greet")
        let misspelled = run(package, "--jsonn", "greet")

        // Then neither runs the command. Dropped instead of read, a leading word the fork
        // did not understand would run `greet` for someone who asked for the manual.
        #expect(!help.standardOutput.contains("hello"), "\(help.output)")
        #expect(!misspelled.output.contains("hello"), "\(misspelled.output)")
        #expect(misspelled.status != 0, "\(misspelled.output)")
    }

    @Test("after the name the word is the command's, both ways of writing the call")
    func leavesTheWordAfterTheNameToTheCommand() throws {
        // Given
        let package = try bundled("echoes", manifest: .manifest(
            named: "echoes",
            commands: "say = \"echo\""
        ))

        // When
        let short = run(package, "say", "--json")
        let long = run(package, "run", "say", "--json")
        let plain = run(package, "say", "hello")

        // Then the line is the name: past it the runner reads nothing, so the package gets
        // its own argument rather than the runner taking a word that looks like its own.
        #expect(short.standardOutput == "--json\n", "\(short.output)")
        #expect(long.standardOutput == "--json\n", "\(long.output)")
        #expect(plain.standardOutput == "hello\n", "\(plain.output)")
    }

    @Test("a refusal is answered as JSON too, and the exit code is unchanged")
    func refusesInJSON() throws {
        // Given a place with no package, and a package whose manifest cannot be read.
        let unreadable = try bundled("broken", manifest: """
            [open-package]
            version = "\(Environment.version)"

            [package
            name = "broken"
            """)

        // When
        let nowhere = cli.run(["check", "--json"], from: workspace.root)
        let malformed = run(unreadable, "--json")

        // Then the caller that asked for JSON is not handed prose in the one case it most
        // wants to handle mechanically.
        #expect(nowhere.status != 0, "\(nowhere.output)")
        #expect(try decode(nowhere)["reason"] as? String != nil, "\(nowhere.output)")
        #expect(malformed.status != 0, "\(malformed.output)")
        #expect(try #require(decode(malformed)["reason"] as? String).contains("line 4"), "\(malformed.output)")
    }

    @Test("the way out is a key of its own, not a sentence glued to the cause")
    func partsTheCauseFromTheAdvice() throws {
        // Given
        let lone = try loneRunner()

        // When
        let result = cli.run(["check", "--json"], from: workspace.root, runner: lone)
        let record = try decode(result)

        // Then the cause is the library's answer and the advice is this surface's wording,
        // so a caller matching on one is not broken by an edit to the other.
        let reason = try #require(record["reason"] as? String)

        #expect(!reason.contains("Run '"), "\(result.output)")
        #expect(try #require(record["next"] as? String).contains("Run '"), "\(result.output)")
    }

    @Test("a field the manifest never wrote is absent rather than empty")
    func omitsAnUnwrittenDescription() throws {
        // Given the manifest helper writes no description.
        let silent = try bundled("silent", manifest: .manifest(named: "silent"))
        let spoken = try bundled("spoken", manifest: """
            [open-package]
            version = "\(Environment.version)"

            [package]
            name = "spoken"
            version = "0.1.0"
            description = "says something"

            [command]
            verify = "true"
            """)

        // When
        let quiet = try #require(try decode(run(silent, "--json"))["package"] as? [String: Any])
        let loud = try #require(try decode(run(spoken, "--json"))["package"] as? [String: Any])

        // And a name that came through as nothing is not spelled as a value either.
        let nameless = try bundled("nameless-json", manifest: """
            [open-package]
            version = "\(Environment.version)"

            [package]
            version = "0.1.0"

            [command]
            verify = "true"
            """)

        // Then
        #expect(quiet["description"] == nil)
        #expect(loud["description"] as? String == "says something")
        #expect(try #require(try decode(run(nameless, "--json"))["package"] as? [String: Any])["name"] == nil)
    }

    @Test("the way in the footer names is the way the rows say is open")
    func namesAReachableWayIn() throws {
        // Given a package whose only command is a name this runner answers first.
        let reserved = try bundled("reserved", manifest: .manifest(
            named: "reserved",
            commands: "check = \"echo hi\""
        ))
        let open = try bundled("open", manifest: .manifest(
            named: "open",
            commands: "greet = \"echo hi\""
        ))

        // When
        let unreachable = run(reserved)
        let reachable = run(open)

        // Then the footer does not send anyone to a form the listing marks as closed.
        // Named, not a placeholder. A line that says `run <command>` under a row marked
        // `(run -- -x)` leaves the reader to work out which of the two the screen meant.
        #expect(unreachable.standardOutput.contains("'open-package run check'"), "\(unreachable.output)")
        #expect(!unreachable.standardOutput.contains("'open-package <command>'"), "\(unreachable.output)")
        #expect(reachable.standardOutput.contains("'open-package <command>'"), "\(reachable.output)")
    }

    @Test("the manual explains how package commands are reached")
    func documentsPassthrough() throws {
        // Given
        let package = try bundled("good", manifest: .manifest(named: "good"))

        // When
        let result = run(package, "--help")

        // Then
        #expect(result.standardOutput.contains("PACKAGE COMMANDS"), "\(result.output)")
        #expect(result.standardOutput.contains("WHICH PACKAGE"), "\(result.output)")
    }

    @Test("arguments reach the command, and a space keeps them together")
    func passesArgumentsThrough() throws {
        // Given
        let package = try bundled("good", manifest: .manifest(
            named: "good",
            commands: "echo = \"echo\"\nverify = \"true\""
        ))

        // When
        let plain = run(package, "echo", "hello", "world")
        let spaced = run(package, "echo", "a b", "c")

        // Then
        #expect(plain.standardOutput == "hello world\n", "\(plain.output)")
        #expect(spaced.standardOutput == "a b c\n", "\(spaced.output)")
    }

    @Test("a command that places \"$@\" itself decides where the arguments land")
    func honoursExplicitArgumentPlacement() throws {
        // Given a line whose tail is not where arguments belong.
        let package = try bundled("good", manifest: .manifest(
            named: "good",
            commands: #"""
                tail = "echo one; echo two"
                placed = "echo \"$@\"; echo two"
                verify = "true"
                """#
        ))

        // When
        let appended = run(package, "tail", "given")
        let placed = run(package, "placed", "given")

        // Then
        #expect(appended.standardOutput == "one\ntwo given\n", "\(appended.output)")
        #expect(placed.standardOutput == "given\ntwo\n", "\(placed.output)")
    }

    @Test("a manifest that cannot be read says so rather than reporting no package")
    func reportsAnUnreadableManifest() throws {
        // Given
        let package = try bundled("broken", manifest: """
            [open-package]
            version = "\(Environment.version)"

            [package
            name = "broken"
            """)

        // When
        let result = run(package)

        // Then
        #expect(result.status != 0, "\(result.output)")
        #expect(!result.output.contains("No package here"), "\(result.output)")
        #expect(result.output.contains("line 4"), "\(result.output)")
    }

    @Test("commands run from the package root even when called from inside it")
    func runsFromThePackageRoot() throws {
        // Given
        let package = try bundled("located", manifest: .manifest(
            named: "located",
            commands: "where = \"pwd\"\nverify = \"true\""
        ))
        let deep = package.appendingPathComponent("source/nested")
        try FileManager.default.createDirectory(at: deep, withIntermediateDirectories: true)

        // When
        let result = cli.run(["where"], from: deep)

        // Then
        let reported = URL(
            fileURLWithPath: result.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        #expect(canonical(reported) == canonical(package), "\(result.output)")
    }

    @Test("the command's exit code is the runner's exit code")
    func propagatesExitCode() throws {
        // Given
        let package = try bundled("exits", manifest: .manifest(
            named: "exits",
            commands: "verify = \"exit 3\""
        ))

        // When
        let result = run(package, "verify")

        // Then
        #expect(result.status == 3, "\(result.output)")
    }

    @Test("an unknown command fails")
    func refusesUnknownCommand() throws {
        // Given
        let package = try bundled("good", manifest: .manifest(named: "good"))

        // When
        let result = run(package, "nope")

        // Then
        #expect(result.status != 0, "\(result.output)")
    }

    @Test("run reaches a name the runner would otherwise answer first")
    func runReachesAReservedName() throws {
        // Given a package that declares a word this runner has taken.
        let package = try bundled("good", manifest: .manifest(
            named: "good",
            commands: "check = \"echo the package answered\""
        ))

        // When
        let short = run(package, "check")
        let long = run(package, "run", "check")

        // Then the short form is the runner's, and nothing a manifest states is out of reach.
        // The inspection it runs reports the conflicting name, which is how a package finds out.
        #expect(!short.standardOutput.contains("the package answered"), "\(short.output)")
        #expect(short.output.contains(BuiltinCommand.run.rawValue), "\(short.output)")
        #expect(long.standardOutput.contains("the package answered"), "\(long.output)")
    }

    @Test("run leaves the arguments to the command, including ones shaped like options")
    func runPassesOptionsThrough() throws {
        // Given
        let package = try bundled("good", manifest: .manifest(
            named: "good",
            commands: "greet = \"echo\""
        ))

        // When
        let result = run(package, "run", "greet", "--help")

        // Then `--help` was addressed past the runner, so the runner did not answer it.
        #expect(result.standardOutput.contains("--help"), "\(result.output)")
        #expect(!result.standardOutput.contains("OVERVIEW"), "\(result.output)")
    }

    @Test("run carries the command's exit code out, the way the short form does")
    func runReportsTheCommandStatus() throws {
        // Given
        let package = try bundled("good", manifest: .manifest(
            named: "good",
            commands: "verify = \"exit 3\""
        ))

        // When
        let result = run(package, "run", "verify")

        // Then
        #expect(result.status == 3, "\(result.output)")
    }

    @Test("a package this runner does not support runs nothing")
    func refusesUnsupportedPackages() throws {
        // Given the cases are written against the running binary's own version. Spelling
        // them out would mean editing this suite on every release, and an edit made to get
        // back to green can agree with whatever the gate now does.
        let running = Environment.version
        let unsupported = [
            "\(running.major + 97).0.0",
            "\(running.major + 1).0.0",
            "\(running.major).\(running.minor + 1).0"
        ]

        for required in unsupported {
            // Given
            let package = try bundled("elsewhere-\(required)", manifest: .manifest(
                named: "elsewhere",
                requiring: required
            ))

            // When
            let result = run(package, "verify")

            // Then
            #expect(result.status != 0, "\(required): \(result.output)")
        }
    }

    @Test("a package written for this major's first version still runs")
    func supportsOlderPackages() throws {
        // Given
        let package = try bundled("older", manifest: .manifest(
            named: "older",
            requiring: "\(Environment.version.major).0.0",
            commands: "verify = \"true\""
        ))

        // When
        let result = run(package, "verify")

        // Then
        #expect(result.status == 0, "\(result.output)")
    }

    @Test("a manifest that states no open-package version is refused")
    func refusesUndeclaredRequirement() throws {
        // Given
        let package = try bundled("silent", manifest: """
            [package]
            name = "silent"
            version = "0.1.0"

            [command]
            verify = "true"
            """)

        // When
        let result = run(package, "verify")

        // Then
        #expect(result.status != 0, "\(result.output)")
    }

    @Test("a malformed manifest is refused with the line that caused it")
    func reportsManifestLine() throws {
        // Given
        let package = try bundled("broken", manifest: """
            [open-package]
            version = "\(Environment.version)"

            [package]
            id = broken
            """)

        // When
        let result = run(package, "check")

        // Then
        #expect(result.status != 0, "\(result.output)")
        #expect(result.output.contains("line 5"), "\(result.output)")
    }

    @Test("a runner standing on its own explains itself and creates the first package")
    func worksWithoutAPackage() throws {
        // Given
        let lone = try loneRunner()
        let destination = workspace.path("created-by-a-lone-runner")

        // When
        let usage = cli.run([], from: workspace.root, runner: lone)
        let specification = cli.run([BuiltinCommand.spec.rawValue], from: workspace.root, runner: lone)
        let created = cli.run([BuiltinCommand.new.rawValue, destination.path], from: workspace.root, runner: lone)
        let check = cli.run([BuiltinCommand.check.rawValue], from: workspace.root, runner: lone)

        // Then
        #expect(usage.standardOutput.contains("No package here"), "\(usage.output)")
        #expect(specification.status == 0, "\(specification.output)")
        #expect(created.status == 0, "\(created.output)")
        #expect(check.status != 0, "check has nothing to check and should say so")
    }

    @Test("a package it creates passes check at once and fails verify until one is written")
    func createsValidButUnfinishedPackages() throws {
        // Given
        let package = try bundled("good", manifest: .manifest(named: "good"))
        let destination = workspace.path("created")

        // When
        let created = run(package, BuiltinCommand.new.rawValue, destination.path)
        let check = cli.run(["check"], from: destination)
        let verify = cli.run(["verify"], from: destination)
        let again = run(package, BuiltinCommand.new.rawValue, destination.path)

        // Then
        #expect(created.status == 0, "\(created.output)")
        #expect(check.status == 0, "\(check.output)")
        #expect(verify.status != 0, "an unwritten verify must not pass")
        #expect(again.status != 0, "an existing path must be refused")

    }

    // MARK: - Private
    private func bundled(_ name: String, manifest: String) throws -> URL {
        guard let binary = cli.binary else {
            Issue.record("the CLI binary was not built, and this suite drives the real executable")
            throw CLIRunner.Missing()
        }

        return try workspace.package(name, manifest: manifest)
    }

    private func loneRunner() throws -> URL {
        guard let binary = cli.binary else {
            Issue.record("the CLI binary was not built, and this suite drives the real executable")
            throw CLIRunner.Missing()
        }

        let lone = workspace.path("lone-runner")
        try? FileManager.default.removeItem(at: lone)
        try FileManager.default.copyItem(at: binary, to: lone)

        return lone
    }

    /// The temporary directory reaches the same place by two names, so compare what the file
    /// system resolves rather than what each side happens to spell.
    private func canonical(_ url: URL) -> String {
        guard let resolved = realpath(url.path, nil) else { return url.path }
        defer { free(resolved) }

        return String(cString: resolved)
    }

    /// Runs the built binary, standing inside the given package.
    private func run(_ package: URL, _ arguments: String...) -> CLIRunner.Result {
        cli.run(arguments, from: package)
    }

    /// The JSON surface promises a caller can parse what it reads, so the suite parses it
    /// rather than searching the text for words that would also match a screen.
    private func decode(_ result: CLIRunner.Result) throws -> [String: Any] {
        let parsed = try JSONSerialization.jsonObject(
            with: Data(result.standardOutput.utf8)
        )

        return try #require(parsed as? [String: Any], "\(result.output)")
    }
}
