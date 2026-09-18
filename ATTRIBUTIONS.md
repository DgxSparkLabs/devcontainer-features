# Attributions

This repository aggregates and maintains dev container Features.
Each Feature retains the copyright and license of its original author;
the repository packaging, tooling, and documentation are maintained by DgxSparkLabs.
The table below records the origin of every Feature distributed here.

| Feature | Original author | Source | License |
|---|---|---|---|
| bitwarden-cli | Markus Zhang ([@RouL](https://github.com/RouL)) | [RouL/devcontainer-features](https://github.com/RouL/devcontainer-features) | MIT |
| bitwarden-secrets-manager | Markus Zhang ([@RouL](https://github.com/RouL)) | [RouL/devcontainer-features](https://github.com/RouL/devcontainer-features) | MIT |
| mise | Markus Zhang ([@RouL](https://github.com/RouL)) | [RouL/devcontainer-features](https://github.com/RouL/devcontainer-features) | MIT |
| vault | Markus Zhang ([@RouL](https://github.com/RouL)) | [RouL/devcontainer-features](https://github.com/RouL/devcontainer-features) | MIT |

## Adding a Feature from Another Author

When a Feature is sourced from someone else, credit travels with it:

1. Preserve the original author's copyright notice and license text alongside the Feature.
2. Add an `## Attribution` section to `src/<feature>/NOTES.md` naming the author and
   linking the source; `generate-docs` appends it to the published Feature README.
3. Add a row to the table above with the author, source, and license.

If a Feature has deeper upstream origins than its immediate source,
add those origins here as well so the full provenance is recorded.
