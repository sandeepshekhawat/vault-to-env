# Security

Vault to Env is designed to handle secret data (e.g. from vaults or config). We take that seriously.

## Data handling

- **No network:** The app does not send input, output, or clipboard content over the network.
- **No persistence of secrets:** Input and output are cleared when the window closes. Preferences store only non-secret settings (e.g. “show in dock”, “paste on open”).
- **No logging of secrets:** Secret content is not written to logs or crash reports.

## Reporting a vulnerability

If you believe you’ve found a security issue, please report it responsibly:

1. **Do not** open a public issue for security-sensitive bugs.
2. Open a [private security advisory](https://github.com/sandeepshekhawat/vault-to-env/security/advisories/new) on GitHub, or email the maintainer if you have contact details.

We’ll respond as soon as we can and will credit you for the report if you’re comfortable with that.
