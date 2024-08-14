# TUF verification

## How-to verify root key attestations

1.  Retrieve Yubico PIV CA certificate from Yubico

    ```sh
    curl https://developers.yubico.com/PIV/Introduction/piv-attestation-ca.pem -o piv-attestation-ca.pem
    ```

1.  Build `key-verification` tool

    ```sh
    go build ./tools/key-verification
    ```

1.  Run `key-verification`

    ```sh
    ROOT_KEYS_PATH=./ceremony/YYYY-MM-DD/keys ./key-verification
    ```

The output should look something like:

```console
$ ROOT_KEYS_PATH=./ceremony/2024-06-04/keys ./key-verification
YubiKey Serial Number: 25515003
Public Key:
-----BEGIN PUBLIC KEY-----
MHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEYTPARe9DPvvVVf7ch5fTVWXtS9FS97lh
yZr3Pk33qRprnVB9u7BaEzvQtTYycPO7cmYW5yTOC5ZZa9p2B/v15bOK4NTU0WTT
XTwSgKmJDh8CD/PBp386S8cwyyIp7NiR
-----END PUBLIC KEY-----

Device attestation verified for: 25515003
YubiKey Serial Number: 25515137
Public Key:
-----BEGIN PUBLIC KEY-----
MHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEl7Uv9j5PVw4nO0MMFBgey+4Mg+LWv7Ks
EQrMMJM6i15C7tXttOLpiNUPlKorCYDbzfQAfvZhieSifneiil7m9ZX5lsQSfPiy
+l3c+vw2FBTJYILrfRCX9i5NiLMxSc1m
-----END PUBLIC KEY-----

Device attestation verified for: 25515137
…
```

## How-to generate YubiKey PIV attestation certificates

1.  Download and install
    [yubico-piv-tool](https://developers.yubico.com/yubico-piv-tool/Releases/)

1.  Create a new directory using your device serial number

    ```sh
    mkdir -p ./keys/<serial>
    ```

1.  Read Yubikey PIV device certificate in slot f9

    ```sh
    yubico-piv-tool --action=read-certificate --slot=f9 > ./keys/<serial>/SlotF9Intermediate.pem
    ```

1.  Read PIV attestation certificate for Digital Signature certificate in slot
    9c

    ```sh
    yubico-piv-tool --action=attest --slot=9c > ./keys/<serial>/Slot9CAttestation.pem
    ```
