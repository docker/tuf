## How-to Generate YubiKey PIV Attestation Certificates

1. Download and install [yubico-piv-tool](https://developers.yubico.com/yubico-piv-tool/Releases/)

1. Create a new directory using your device serial number
   ```sh
   mkdir -p ./keys/<serial>
   ```
1. Read Yubikey PIV device certificate in slot f9
   ```sh
   yubico-piv-tool --action=read-certificate --slot=f9 > ./keys/<serial>/SlotF9Intermediate.pem
   ```

1. Read PIV attestation certificate for Digital Signature certificate in slot 9c
   ```sh
   yubico-piv-tool --action=attest --slot=9c > ./keys/<serial>/Slot9CAttestation.pem
   ```

## How-to Verify Root Key Attestations

1. Retrieve Yubico PIV CA certificate from Yubico
   ```sh
   curl https://developers.yubico.com/PIV/Introduction/piv-attestation-ca.pem -o piv-attestation-ca.pem
   ```

1. Build `key-verification` tool
   ```sh
   go build ./tools/key-verification
   ```
1. Run `key-verification`
   ```sh
   ROOT_KEYS_PATH=./ceremony/YYYY-MM-DD/keys ./key-verification
   ```

### example output

```log
> ROOT_KEYS_PATH=./ceremony/2024-04-05/keys ./key-verification

YubiKey Serial Number: 25516106
Public Key:
-----BEGIN PUBLIC KEY-----
MHYwEAYHKoZIzj0CAQYFK4EEACIDYgAE3+asmp2GD6UijwWvMezwVG/BwFLuQa3o
T6eRxFvkILGpVDbZ92ZYWidHl9LZ/eJUjhIjuVEkNVKoenw5KjKl8veP3MthZrQA
SkYytOIwkidZo9Rk2dczbDcFSJvLGsmd
-----END PUBLIC KEY-----

Device attestation verified for: 25516106
```
