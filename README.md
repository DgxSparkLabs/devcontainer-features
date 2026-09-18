# Dev Container Features

## Contents

This repository contains the following features:

- [Bitwarden CLI (bw)](./src/bitwarden-cli/README.md): Installs the bitwarden CLI (bw) and optionally configures it to use a self-hosted server.
- [Bitwarden Secrets Manager CLI (bws)](./src/bitwarden-secrets-manager/README.md): Installs the bitwarden secrets manager CLI (bws) and optionally configures it to use a self-hosted server.
- [Mise - mise-en-place version manager](./src/mise/README.md): Installs mise-en-place version manager.
- [HashiCorp Vault](./src/vault/README.md): Installs the HashiCorp Vault binary.

## Usage

To use the features from this repository, add the desired features to devcontainer.json.

This example uses the **mise** feature:

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/DgxSparkLabs/devcontainer-features/mise:1": {}
    }
}
```
