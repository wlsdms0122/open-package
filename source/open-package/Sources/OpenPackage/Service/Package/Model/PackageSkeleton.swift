//
//  PackageSkeleton.swift
//  OpenPackage
//
//  Created by JSilver on 8/30/26.
//

/// What a package looks like before anyone has written anything into it.
struct PackageSkeleton: Sendable {
    // MARK: - Property
    /// What a package written today actually needs: the first version of this major.
    ///
    /// A new package uses nothing that was added after the format opened, so declaring the
    /// version that minted it would make a runner's own patch release a compatibility event:
    /// a 1.0.2 runner refusing what 1.0.3 wrote, over a bug fix neither package touched. The
    /// field means the least version whose behaviour is needed, and this is that.
    private static var requiredRunner: Version { Version(major: Environment.version.major) }

    /// The directory the package is being made in. It is the starting value for
    /// `[package] name` and nothing more: the two are free to differ from the first edit,
    /// since the directory is already the answer to which package this is.
    let identifier: String

    var manifest: String {
        """
        # The specification is `open-package spec`

        [open-package]
        version = "\(Self.requiredRunner)"

        [package]
        name = "\(identifier)"
        version = "0.1.0"
        description = ""
        requires = []

        [command]
        # Commands run from the package root, and no name means anything but this line.
        # Arguments are appended, unless the line places "$@" itself.
        verify = "! echo 'verify is not written yet' >&2"

        """
    }

    var readme: String {
        """
        # \(identifier)

        <What this package is, and what it is good for.>

        This directory is an **open-package**. See `open-package spec`.

        ## Usage

        ```
        open-package verify
        ```

        ## What is inside

        | Path | Role |
        |---|---|
        | `source/` | |
        | `document/` | |

        """
    }

    // MARK: - Initializer
    init(identifier: String) {
        self.identifier = identifier
    }

    // MARK: - Public
    // MARK: - Private
}
