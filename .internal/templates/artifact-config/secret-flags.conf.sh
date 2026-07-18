# Flags for optional secrets targets. Target-specific flags are named
# BACKUP_<KEY_IN_UPPERCASE>, for example BACKUP_NETRC=false,
# BACKUP_GRADLE_PROPERTIES=false, or BACKUP_POSTMAN=false.

BACKUP_SSH=true
BACKUP_GNUPG=true
BACKUP_DOCKER=true    # Docker settings -> app-backups/docker/
                      # Docker config.json -> secrets-encrypted/docker/config.json via SECRETS_TARGETS
BACKUP_POSTMAN=true   # Manual Postman secret staging folder -> secrets-encrypted/postman/
BACKUP_JAVA_JSSECACERTS=true  # Corporate Java trust override -> secrets-encrypted/certs/java-security/
