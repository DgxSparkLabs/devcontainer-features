
# Bitwarden Secrets Manager CLI (bws) (bitwarden-secrets-manager)

Installs the bitwarden secrets manager CLI (bws) and optionally configures it to use a self-hosted server.

## Example Usage

```json
"features": {
    "ghcr.io/DgxSparkLabs/devcontainer-features/bitwarden-secrets-manager:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| server_base | Provides the base URL of your Bitwarden server, if you host your own server. | string | - |
| server_api | Provides an API URL that differs from the default (if in doubt, leave it empty!). | string | - |
| server_identity | Provides an identity URL that differs from the default (if in doubt, leave it empty!). | string | - |

## Attribution

This Feature was originally created by [Markus Zhang](https://github.com/RouL)
as part of [RouL/devcontainer-features](https://github.com/RouL/devcontainer-features),
and is redistributed here under the MIT License.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/DgxSparkLabs/devcontainer-features/blob/main/src/bitwarden-secrets-manager/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
