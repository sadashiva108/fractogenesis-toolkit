# ONEDRIVE EXTRA EXCLUDES
# Applied in addition to EXTERNAL_EXCLUDES for OneDrive syncs only.
# Use to strip anything not appropriate for corporate cloud storage.

ONEDRIVE_EXTRA_EXCLUDES=(

  # -- Personal — keep off corporate cloud -------------------------------------
  "Personal/"

  # -- Dev folders — fine on external drive, not needed in OneDrive ------------
  "DockerDesktop/"
  "github-copilot-intellij/"
  "Kubernetes/"
  "Falcon/"
  "Dynatrace/"

  # -- Sensitive file types — keep off corporate cloud -------------------------
  "*.pem"
  "*.key"
  "*.p12"
  "*.pfx"
  "*.cer"
  "*.crt"
  "*.der"
  "*.p7b"
  "*.p8"
  "*.rayconfig"
  "*.env"
  "*.env.local"
  "http-client.private.env.json"
  ".netrc"
  ".git-credentials"
  ".pypirc"
  ".yarnrc"
  ".yarnrc.yml"
  "settings.xml"
  "gradle.properties"
  "credentials"
  "*.keystore"
  "*.jks"
  "*.exe"
  "*.dll"
  "*.msi"
  "*.bat"
  "*.cmd"
  "*.ps1"
  "node_modules/"
  ".vscode/extensions/"
  "github-copilot/"
  "github-copilot-intellij/"
)
