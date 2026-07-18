# SECRETS TARGETS
# Written to secrets-encrypted/, not home-files-backup/.
# Handled specially by backup-home.sh.
#
# Format: "KEY | SOURCE | DEST_RELATIVE_TO_secrets-encrypted/ | DESCRIPTION"
#
# Java jssecacerts is dynamic because it can live under JAVA_HOME,
# /Library/Java/JavaVirtualMachines, or a bundled IntelliJ JBR. It is controlled
# by BACKUP_JAVA_JSSECACERTS below instead of this static array.

SECRETS_TARGETS=(
  "ssh               | $HOME/.ssh/                         | ssh                          | SSH private keys and config — chmod 700/600 preserved"
  "gnupg             | $HOME/.gnupg/                       | gnupg                        | GPG private keys — permanent loss without backup; random_seed excluded"
  "docker            | $HOME/.docker/config.json           | docker/config.json           | Docker auth config — credential helpers, auth tokens, and registry login state"
  "keystore          | $HOME/.keystore                     | certs/.keystore              | Java KeyStore — signing keys and TLS certs; store password and key alias in LastPass"
  "netrc             | $HOME/.netrc                        | cli-credentials/.netrc       | FTP/HTTP credentials used by command-line tools"
  "git_credentials   | $HOME/.git-credentials              | git/.git-credentials         | Git credential helper plaintext credential cache, if present"
  "npmrc             | $HOME/.npmrc                        | package-managers/.npmrc      | npm registry configuration; may contain auth tokens"
  "yarnrc            | $HOME/.yarnrc                       | package-managers/.yarnrc     | Yarn v1 registry configuration; may contain auth tokens"
  "yarnrc_yml        | $HOME/.yarnrc.yml                   | package-managers/.yarnrc.yml | Yarn Berry registry configuration; may contain npm auth tokens"
  "pypirc            | $HOME/.pypirc                       | package-managers/.pypirc     | Python package repository credentials, if present"
  "gradle_properties | $HOME/.gradle/gradle.properties     | package-managers/gradle.properties | Gradle properties; may contain internal repo credentials or tokens"
  "maven_settings    | $HOME/.m2/settings.xml              | package-managers/maven-settings.xml | Maven settings; may contain server credentials or tokens"
  "kube_config       | $HOME/.kube/config                  | kube/config                  | Kubernetes config with cluster credentials and context definitions"
  "aws               | $HOME/.aws/                         | cloud/aws                    | AWS CLI profiles, config, cached SSO material, and credentials when present"
  "postman           | $MANUAL_POSTMAN_STAGE               | postman                      | Manual Postman secret staging — environments, Vault exports, and unreviewed credential-bearing exports"
  "gh_hosts          | $HOME/.config/gh/hosts.yml        | cli-credentials/gh/hosts.yml | GitHub CLI host/auth config; may contain authentication material"
)
