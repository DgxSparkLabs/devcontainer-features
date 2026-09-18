
# Bitwarden CLI (bw) (bitwarden-cli)

Installs the bitwarden CLI (bw) and optionally configures it to use a self-hosted server.

## Example Usage

```json
"features": {
    "ghcr.io/DgxSparkLabs/devcontainer-features/bitwarden-cli:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| server | Provides the URL of your Bitwarden server, if you host your own server. | string | - |
| web_vault | Provides a custom web vault URL that differs from the base URL. | string | - |
| api | Provides a custom API URL that differs from the base URL. | string | - |
| identity | Provides a custom identity URL that differs from the base URL. | string | - |
| icons | Provides a custom icons service URL that differs from the base URL. | string | - |
| notifications | Provides a custom notifications URL that differs from the base URL. | string | - |
| events | Provides a custom events URL that differs from the base URL. | string | - |
| key_connector | Provides the URL for your Key Connector server. | string | - |

## Attribution

This Feature was originally created by [Markus Zhang](https://github.com/RouL)
as part of [RouL/devcontainer-features](https://github.com/RouL/devcontainer-features),
and is redistributed here under the MIT License.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/DgxSparkLabs/devcontainer-features/blob/main/src/bitwarden-cli/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
