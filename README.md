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
Secrets.register(:staging, create: true)
Secrets.register(:production, create: true)

Secrets[:staging][:API_KEY] = "555-555-ASDF-445"
Secrets[:staging]["some other key"] = "8j98ajsdf"
Secrets[:production][:something] = "something else"

# writes encryption key to .staging_secret_key and encrypted
# secrets to secrets/staging_secrets.enc.yml
Secrets[:staging].save

# on a subsequent run, this will load the previously saved staging secrets
Secrets.register(:staging) # => returns instance of Secrets for staging
Secrets.register(:shared) # => returns false as we haven't saved shared secrets
```

Note: each time you `save` an secret store, you will get differing file
contents even if no secrets have been added, removed, or changed. This is
a security feature and the result of us using nonces.

## Best Practices
* Do not commit encryption keys (e.g. `.production_secret_key`) to a repo!
* Do not accidentally bake an encryption key into a public Docker image!
* Do not commit code that directly sets secrets like above, obviously
  this will add the secrets in plaintext form to your repo!
* Distribute encryption keys to trusted developers if they need to have
  access to the corresponding secrets
* Use multiple secret stores for different types of secrets i.e. `production`,
  `development`, and `shared` if you have secrets used by one or more environment
* Integrate this library in some way with your app / dev environment so you have
  a way to quickly edit encrypted secrets. Right now this is left up to the user,
  however a later version may provide some sort of CLI for doing this similar
  to [Amber](https://amberframework.org)'s `amber encrypt`.
* Provide the necessary encryption keys when running deployments
