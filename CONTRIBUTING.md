# Contributing code

This repository is a collection of dev container Features maintained by [DgxSparkLabs].
It accepts improvements and bug fixes for the [current set of maintained Features], and it
also aggregates Features authored by others, redistributed with full credit to their
original creators.

Every Feature keeps the copyright and license of its original author. When a Feature comes
from someone else, its original license and copyright notice are preserved, its author is
credited in `src/<feature>/NOTES.md`, and it is recorded in [ATTRIBUTIONS.md].

If you've identified an issue and you want to fix it, here's how you can get
started:

1. Fork the repo
2. Open the repo in your editor
3. Add your changes to your workspace
4. Add additional tests to your workspace if neccessary
5. Test your changes using `bin/test <feature name>` to make sure everything still works
6. Bump the version of the feature you changed according to [semver]
7. Commit & push your changes
8. Open a PR to get your changes merged

## Adding a Feature from Another Author

We welcome Features created by others. To add one while respecting its license:

1. Copy the Feature into `src/<feature>/` with its `devcontainer-feature.json` and `install.sh`
2. Preserve the original author's copyright notice and license text with the Feature
3. Credit the author in `src/<feature>/NOTES.md` under an `## Attribution` heading
4. Add a row for the Feature to [ATTRIBUTIONS.md]
5. Add tests under `test/<feature>/` and open a PR

[DgxSparkLabs]: https://github.com/DgxSparkLabs
[current set of maintained Features]: https://github.com/DgxSparkLabs/devcontainer-features/tree/main/src
[devcontainers/feature-starter]: https://github.com/devcontainers/feature-starter#readme
[adding it to the index]: https://github.com/devcontainers/feature-starter#adding-features-to-the-index
[semver]: https://semver.org/
[ATTRIBUTIONS.md]: ./ATTRIBUTIONS.md
