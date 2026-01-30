=
                         CERTKIT-BLACKFORGE
=
<img width="1217" height="998" alt="imagen" src="https://github.com/user-attachments/assets/055831d1-4cf7-4262-be53-4116bb21e853" />
Certkit-Blackforge is an all-in-one tool for managing SSL/TLS
certificates on Linux systems.

It is designed for system administrators, DevOps, SREs, and security
teams who need to create, sign, convert, and install certificates in a
simple, guided, and portable way.


---------------------------------------------------------------------
MAIN FEATURES
---------------------------------------------------------------------

- Interactive menu-driven interface
- Multilingual support (Spanish / English)
- Compatible with multiple Linux distributions
- Full SSL/TLS certificate lifecycle management
- Let’s Encrypt (ACME) support
- Internal CA (Root / signed certificates)
- Client certificates (mTLS)
- Wildcard certificates (*.domain.com)
- Self-signed certificates
- Java Keystore (cacerts) support
- Automatic dependency detection and installation
- Hacker-style green Matrix banner
- Clean, portable Bash code with minimal dependencies


---------------------------------------------------------------------
SUPPORTED DISTRIBUTIONS
---------------------------------------------------------------------

- Debian / Ubuntu
- Red Hat Enterprise Linux
- Rocky Linux
- AlmaLinux
- Arch Linux
- SUSE / openSUSE

The script automatically detects the distribution and installs the
required dependencies.


---------------------------------------------------------------------
REQUIREMENTS
---------------------------------------------------------------------

- Bash 4 or newer
- Root access
- OpenSSL
- curl

Optional:
- certbot (for Let’s Encrypt)
- acme.sh (for DNS-01 and wildcard certificates)

Missing dependencies are installed automatically when possible.


---------------------------------------------------------------------
INSTALLATION
---------------------------------------------------------------------

1. Clone the repository:

   git clone https://github.com/StealthByte0/certkit-blackforge.git

2. Enter the directory:

   cd certkit-blackforge

3. Grant execution permissions:

   chmod +x Certkit-Blackforge.sh

4. Run as root:

   sudo ./Certkit-Blackforge.sh


---------------------------------------------------------------------
GENERAL USAGE
---------------------------------------------------------------------

When starting the tool:

1. Select the language
2. Navigate through the interactive menu
3. Choose the certificate type
4. Enter the requested information when prompted

No need to memorize OpenSSL commands or manually edit config files.


---------------------------------------------------------------------
SUPPORTED CERTIFICATE TYPES
---------------------------------------------------------------------

- SSL certificates via Let’s Encrypt
- Wildcard certificates (*.domain.com)
- Self-signed certificates
- Local Root CA
- Certificates signed by an internal CA
- Client certificates (mTLS)
- Export to PEM and PFX formats
- Import certificates into Java cacerts


---------------------------------------------------------------------
PROJECT STRUCTURE
---------------------------------------------------------------------

certkit-blackforge/
|
|-- Certkit-Blackforge.sh
|-- README.txt
|-- docs/


---------------------------------------------------------------------
IMPORTANT NOTES
---------------------------------------------------------------------

- For Let’s Encrypt HTTP-01, port 80 must be available
- For wildcard certificates, DNS-01 validation is recommended
- Always run the script as root
- Do not use in production without understanding the impact
- Always back up private keys and certificates


---------------------------------------------------------------------
BEST PRACTICES
---------------------------------------------------------------------

- Use client certificates (mTLS) for internal APIs
- Use an internal CA for closed environments
- Automate certificate renewals when possible
- Never share private keys
- Keep secure backups of certificates and keys


---------------------------------------------------------------------
AUTHOR
---------------------------------------------------------------------

Author: – ラストドラゴン
Alias: @Bl4ckD34thz
X (Twitter): https://x.com/bl4ckd34thz


---------------------------------------------------------------------
LICENSE
---------------------------------------------------------------------

This project is distributed under the MIT License.

You are free to:
- Use it
- Modify it
- Distribute it
- Integrate it into other projects

At your own risk.


---------------------------------------------------------------------
CONTRIBUTIONS
---------------------------------------------------------------------

Contributions are welcome.

If you find a bug or issue:
1. Open an issue
2. Describe the environment
3. Include logs (without sensitive data)


---------------------------------------------------------------------
DISCLAIMER
---------------------------------------------------------------------

This software is provided "as is", without warranty of any kind.
The author is not responsible for any direct or indirect damage
resulting from the use of this tool.


=====================================================================

