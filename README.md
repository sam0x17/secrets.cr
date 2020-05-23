# secrets.cr

Provides encrypted key-value stores that can be registered, saved, and loaded
by name. Can be used to securely store environment-specific secrets directly
in your repo.

Secrets are encrypted using AES-256 in CBC mode with a nonce and saved IV-first
followed by the encrypted text.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     secrets:
       github: sam0x17/secrets.cr
   ```

2. Run `shards install`
3. add the following to your `.gitignore` to ensure encryption keys
   are not committed by accident:
```
# .gitignore
.*_secret_key
```

## Usage

```crystal
require "secrets"

# creates default stores named staging and production
Secrets.register(:staging)
Secrets.register(:production)

Secrets[:staging][:API_KEY] = "555-555-ASDF-445"
Secrets[:staging]["some other key"] = "8j98ajsdf"
Secrets[:production][:something] = "something else"

# writes encryption key to .staging_secret_key and encrypted
# secrets to secrets/staging_secrets.enc.yml
Secrets[:staging].save

# on a subsequent run, this will load the previously saved staging secrets
Secrets.register(:staging)
```
