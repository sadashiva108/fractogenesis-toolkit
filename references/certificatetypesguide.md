[[stage-certs-keychain|← Back to Stage Certificates and Keychain]]

# Certificate Types Guide

### Table of Contents

- [[#Purpose|Purpose]]
- [[#The Core Building Blocks|The Core Building Blocks]]
- [[#Certificate Authority Roles|Certificate Authority Roles]]
- [[#Common Certificate Uses|Common Certificate Uses]]
- [[#Private Keys and Why They Matter|Private Keys and Why They Matter]]
- [[#Certificate Chains|Certificate Chains]]
- [[#File Formats and Containers|File Formats and Containers]]
- [[#Truststores vs Keystores|Truststores vs Keystores]]
- [[#Java Certificate Files|Java Certificate Files]]
- [[#macOS Keychain Certificate Categories|macOS Keychain Certificate Categories]]
- [[#Common Keychain Locations|Common Keychain Locations]]
- [[#Exportability and Managed Identities|Exportability and Managed Identities]]
- [[#How Managed Identities Are Delivered|How Managed Identities Are Delivered]]
- [[#Inspecting Identities and Profiles|Inspecting Identities and Profiles]]
- [[#Mapping a Certificate to Its Profile|Mapping a Certificate to Its Profile]]
- [[#Managed Identity Decision Tree|Managed Identity Decision Tree]]
- [[#What Usually Needs Backup vs What Usually Does Not|What Usually Needs Backup vs What Usually Does Not]]
- [[#Quick Decision Guide|Quick Decision Guide]]
- [[#Related Notes|Related Notes]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

---

## Purpose

This guide explains the main kinds of certificates, keys, certificate containers, trust stores, and Keychain items you are likely to encounter.

Use it when you need to answer questions such as:

- what kind of certificate this is
- whether it contains only public material or also a private key
- whether it belongs in a truststore, a keystore, or Keychain
- whether it is likely safe to re-create or whether it needs deliberate backup

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## The Core Building Blocks

| Item | What it is | Secret? |
|---|---|---|
| Certificate | A signed public document that binds an identity to a public key. | No |
| Public key | The public half of a keypair. Used to verify signatures or encrypt to the owner. | No |
| Private key | The private half of a keypair. Used to decrypt or sign. | **Yes** |
| Identity | A certificate plus its matching private key. | **Yes** |
| Certificate chain | A leaf certificate plus the CA certificates that signed it. | Usually not secret by itself |

A certificate by itself is usually public. The risk changes when the file or container also includes the private key.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Certificate Authority Roles

| Type | Role | Typical example |
|---|---|---|
| Root CA | Top-level trust anchor. Self-signed. | Public internet root CA or internal corporate root CA |
| Intermediate CA | Sits between root and leaf certificates. | Public web PKI intermediate |
| Issuing CA | The CA that directly signs end-entity certificates. | Internal corporate issuing CA |
| Leaf / end-entity certificate | The certificate actually used by a server, client, person, or app. | `api.example.com` cert, VPN client cert |

In practice, “intermediate CA” and “issuing CA” are often used almost interchangeably. The key point is that they are not the root trust anchor.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Common Certificate Uses

| Use | What the certificate represents | Usually has private key nearby? |
|---|---|---|
| Server TLS certificate | A hostname or service | Yes, on the server |
| Client certificate | A user, device, or workload proving identity to a server | Yes |
| Code-signing certificate | A developer, company, or signing system | Yes |
| Email / S/MIME certificate | A mailbox or person | Yes |
| CA certificate | A trust anchor used to validate others | No |
| Device-management / VPN / corporate identity cert | A managed device or user | Yes, often non-exportable |

The most important distinction is whether the certificate is just trust material or an actual identity with a private key.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Private Keys and Why They Matter

Private keys are the sensitive part.

- A `.cer`, `.crt`, or `.pem` file that contains only a certificate is usually public.
- A `.p12`, `.pfx`, `.jks`, `.keystore`, or `*.key` file may contain private-key material.
- A Keychain item under **My Certificates** often means there is a matching private key.

If a file or Keychain item can authenticate *as you*, *as your device*, or *as a service*, treat it as secret-bearing.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Certificate Chains

A TLS client usually validates a server certificate by walking a chain:

```text
Leaf certificate
  signed by issuing/intermediate CA
  signed by root CA
  trusted because the root is in the trust store
```

Failures usually mean one of these:

- the issuing or root CA is not trusted
- the wrong hostname was used
- the certificate expired
- a required client certificate is missing

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## File Formats and Containers

| Format | Typical contents | Notes |
|---|---|---|
| PEM (`.pem`) | Base64 text; can hold certs, chains, public keys, or private keys | Must inspect contents, not just extension |
| CRT / CER (`.crt`, `.cer`) | Usually a certificate | Often public-only |
| DER (`.der`) | Binary certificate encoding | Usually public-only |
| KEY (`.key`) | Private key or key-like material | Treat as secret |
| PKCS#12 (`.p12`, `.pfx`) | Certificate(s) plus private key(s), optionally chain | Usually password-protected; secret-bearing |
| JKS (`.jks`) | Java keystore/truststore container | May hold trusted certs, private keys, or both |
| Keystore (`.keystore`) | Generic keystore filename | Content varies; inspect before deciding |

Extensions help, but the actual content is what matters.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Truststores vs Keystores

| Store type | Holds | Main purpose |
|---|---|---|
| Truststore | Trusted CA certificates or trusted leaf certs | Decide what to trust |
| Keystore | Private keys, identities, and sometimes trusted certs | Present identity or hold key material |

Simple rule:

- **truststore** = “who do I trust?”
- **keystore** = “who am I?” or “what keys do I possess?”

Some containers blur this distinction, especially Java stores, so inspect what is actually inside.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Java Certificate Files

| File | Meaning |
|---|---|
| `cacerts` | Default JDK truststore shipped with Java |
| `jssecacerts` | Site-specific override truststore that Java prefers over `cacerts` |
| Custom `*.jks` / `*.p12` truststore | Project or app-specific trust bundle |
| Custom `*.jks` / `*.p12` keystore | Project or app-specific private key / identity store |

`jssecacerts` matters because Java prefers it over `cacerts`. If it exists, it can override default trust behavior entirely.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## macOS Keychain Certificate Categories

In Keychain Access, the category often tells you what kind of item you are looking at:

| Keychain Access view | What it usually means |
|---|---|
| **Certificates** | Public certificate items, often CA or leaf certificates |
| **My Certificates** | Certificate identities that usually have a matching private key |
| **Keys** | Raw private or public key items |
| **Passwords** | Credentials, tokens, or app secrets, not certificates |

The most important distinction:

- **Certificates** often means public material
- **My Certificates** often means identity material and possible private-key sensitivity

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Common Keychain Locations

| Keychain | Typical purpose |
|---|---|
| login | User-specific identities, certs, app secrets |
| System | Machine-wide trust or machine-level identities |
| System Roots | Apple-managed public trust anchors |
| iCloud / synced keychains | User-synced credential material, depending on setup |

For backup and restore decisions:

- **login** often contains the most user-specific certificate identities
- **System** may hold manually added internal trust or device-level items
- **System Roots** is usually managed and not something you back up manually

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Exportability and Managed Identities

Not every Keychain identity can be exported.

Common cases:

| Situation | What it usually means |
|---|---|
| Export succeeds as `.cer` / `.pem` only | Public certificate is accessible, private key may be restricted |
| Export succeeds as `.p12` / `.pfx` | Identity is exportable and can be preserved with password protection |
| Export is blocked or fails | Private key is likely non-exportable, managed, hardware-backed, or policy-restricted |

Managed corporate identities, MDM device identities, VPN identities, and some code-signing or smartcard-backed identities are often intentionally non-exportable. When an export fails with *"Unable to export an item. The contents of this item cannot be retrieved,"* the private key is non-exportable — the next step is not to bypass it but to identify how it is delivered so it can be re-enrolled (see [[#How Managed Identities Are Delivered|How Managed Identities Are Delivered]]).

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How Managed Identities Are Delivered

On a managed Mac, most identities are installed by **configuration profiles**, and the profile's payload type tells you how the identity arrived and whether its private key can leave the device.

| Payload type (`profiles show`) | What it installs | Private key exportable? |
|---|---|---|
| `com.apple.security.root` / `com.apple.security.pkcs1` (as a CA) | A trusted CA / root certificate — trust anchor only | N/A — no private key |
| `com.apple.security.scep` | A leaf identity via **SCEP**: the device generates the keypair locally and requests a certificate from a SCEP/NDES server | **No** — the key is generated on-device and non-exportable |
| `com.apple.security.pkcs12` / PKCS credential | A certificate **and** private key delivered by an MDM certificate connector | Usually installed non-exportable |

Core distinctions:

- **Trusted-CA vs SCEP vs PKCS** — a Trusted-CA payload is only trust material (public). SCEP and PKCS payloads install real identities with private keys. SCEP is the common case for corporate client/device certs and is exactly why "export" fails: the key never existed in exportable form.
- **Intune-native vs internal-PKI** — an *Intune-native* identity is issued by Microsoft's own CAs (`Microsoft Intune Root Certification Authority` → `Microsoft Intune MDM Device CA` or `… MDM Agent CA`); these device/agent identities re-provision automatically on re-enrollment. An *internal-PKI* identity is issued by **your** corporate CA (e.g. an ADCS issuing CA) but still pushed through an Intune SCEP profile pointed at your internal **NDES** endpoint — the issuer is your CA, not a Microsoft CA.
- **Azure AD Workplace Join** — an identity issued by `MS-Organization-Access` is an Azure AD device-registration cert, not an Intune SCEP cert. It re-registers automatically when the device joins Azure AD / enrolls.
- **Enrollment server** — a SCEP profile references a server URL. Intune-native certs point at Intune (`*.manage.microsoft.com`); internal-PKI certs point at your NDES host (for example `https://<ndes-host>/certsrv/mscep/mscep.dll`), and reissue typically needs the corporate network/VPN to reach that host. Note that `profiles show` does **not** print the SCEP URL — read it from System Settings → Device Management.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Inspecting Identities and Profiles

Read-only commands for public metadata (no private keys leave the Keychain):

| Command | What it shows |
|---|---|
| `security find-identity -v` | Keychain identities as `SHA-1  "name"`. The same identity can appear several times (multiple keychains/ACLs) — **dedupe by SHA-1 fingerprint**. |
| `security find-certificate -a -Z -p` | Every certificate as PEM, each preceded by its SHA-1 / SHA-256 hash. |
| `openssl x509 -noout -subject -issuer -enddate -fingerprint -sha1` | Per-cert subject, issuer, expiry, and SHA-1 fingerprint (pipe a PEM block in). |
| `profiles status -type enrollment` | Whether the Mac is DEP/MDM enrolled, and the MDM server. |
| `profiles show` | **USER-level** profiles (your user client certs, e.g. Wi-Fi/SCEP). No sudo. |
| `sudo profiles show` | **COMPUTER-level** profiles (device and agent identities). |

User certs and device certs live in different scopes, so check **both** levels. A quick search:

```bash
sudo profiles show | grep -i -B2 -A6 'scep\|<issuer-CA-name>\|<cert-CN>'
```

`profiles show` lists payload **types and identifiers** — for example `Microsoft.Profiles.SCEP` (device), `Microsoft.Profiles.SCEP.MdmAgent` (agent), and `www.windowsintune.com.*` (Intune) — but not the SCEP server URL or the payload subject, which appear only in the Device Management GUI.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Mapping a Certificate to Its Profile

Because `profiles show` does not print the issued cert's subject, match a Keychain identity to the profile that delivered it by lining up:

- **Subject / CN** — the identity's common name (`openssl … -subject`).
- **Issuer** — which CA signed it (`openssl … -issuer`); this is what tells Intune-native from internal-PKI.
- **Expiry** — disambiguates renewed/duplicate pairs (two certs, same subject, different `notAfter`).
- **Scope + payload identifier** — user vs computer level, plus the SCEP/PKCS identifier (`Microsoft.Profiles.SCEP` = device, `…SCEP.MdmAgent` = agent, a user-level SCEP profile = your client cert).

Build the **issuer chain** by walking subject → issuer through the certs you dumped: the leaf's issuer is a CA whose own subject you can find, up to a self-signed root — for example `Root Corporate CA → Issuing CA → leaf`.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Managed Identity Decision Tree

```text
Look at the identity's ISSUER:
├─ Issuer = MS-Organization-Access
│     → Azure AD device registration (Workplace Join)
│     → Restore: re-registers automatically on Azure AD join / enrollment
├─ Issuer = Microsoft Intune MDM Device CA / Agent CA
│     → Intune-native device/agent SCEP (computer-level)
│     → Restore: re-provisions automatically on Intune re-enrollment
├─ Issuer = your internal corporate CA, and a SCEP profile references it
│     → Intune SCEP via internal PKI / NDES (usually user-level)
│     → Non-exportable; Restore: re-enroll via Intune on corporate network/VPN
├─ Issuer = Subject (self-signed)
│     → Local / self-managed identity — often exportable; back up if you rely on it
└─ No matching profile
      → External PKI / IT-installed, or a genuinely local identity — confirm the source
```

For any non-exportable managed identity the action is **document + re-enroll**, not export. The `keychain-detail` helper (`stage-certs-keychain.sh keychain-detail`) automates this enumeration: it dedupes identities by fingerprint, builds the issuer chain, classifies delivery and exportability, and pre-fills the export checklist — flagging the enrollment-server URL for you to confirm from Device Management.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## What Usually Needs Backup vs What Usually Does Not

| Usually preserve | Usually do not preserve blindly |
|---|---|
| Exportable client identities you actually need | Stock public CA bundles |
| Local-only internal CA certificates you manually trust | App-bundle certificates |
| Local-only project keystores or truststores | Virtualenv or tool cache cert bundles |
| Custom `jssecacerts` or other local Java trust overrides | Default `cacerts` shipped with a JDK |
| Password-protected `.p12` / `.pfx` files you intentionally rely on | Anything clearly regenerated by reinstalling the tool |

The common mistake is backing up every cert-like file. Most public trust material is reproducible; private-key or local override material is what usually deserves attention.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Quick Decision Guide

1. **Is it just a certificate, or an identity with a private key?**
2. **Is it trust material, or authentication material?**
3. **Is it local-only, or regenerated by install / enrollment / sync?**
4. **Is it exportable, or managed and non-exportable?**
5. **Would restore fail without this exact item?**

If the answer points to “identity,” “private key,” “local-only,” or “not easily regenerated,” treat it as deliberate secret material.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Related Notes

- [[stage-certs-keychain|Stage Certificates and Keychain]]
- `PKIK.md`
- `../workflows/mac/reimage/backup-dmg-secrets.md`

[[#Table of Contents|⬆ Back to Table of Contents]]
