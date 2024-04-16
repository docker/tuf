## Production TUF YubiKey Signing Ceremony

## Overview

This document establishes a procedure for the procurement, provisioning, and signing of Docker’s production TUF root.

## Procurement

- Elect an agent to procure and ship devices to keyholders
- Purchase a total of seventeen (17) [YubiKey 5C NFC FIPS](https://www.yubico.com/product/yubikey-5-fips-series/yubikey-5c-nfc-fips/) hardware authenticator devices
    - Purchase two (2) hardware authenticator devices per root keyholder
        - At the time of writing there were five (5) root key holders listed in resulting in a total of ten (10)
    - Purchase one (1) hardware authenticator device per secure artifacts team member
        - At the time of writing there were seven (7) secure artifacts team members listed
    - These groups add up to seventeen (17) devices
- Ship the YubiKey devices directly to each individual key holder
- Each key holder will confirm the serial number of the device(s) they receive according to [Device Serial Verification](#device-serial-verification) instructions

### Device Serial Verification

1. Download and install [YubiKey Manager](https://yubico.com/support/download/yubikey-manager/)
1. Remove the device from the tamper-proof packaging
1. Inspect the backside of the device for the 8-digit serial number
1. Launch YubiKey Manager UI
1. Insert device and record the serial number and firmware version (you will need this data during the signing ceremony)
1. Verify that the device is genuine at [https://www.yubico.com/genuine/](https://www.yubico.com/genuine/)

## Device Provisioning

1. Follow the instructions [YUBIKEY-PIV-SETUP.md](https://github.com/theupdateframework/tuf-on-ci/blob/main/docs/YUBIKEY-PIV-SETUP.md) to provision the YubiKey with a PIV signing certificate with the following options:
    1. For `Set Management Key`
        1. Generate the key on the device
        1. Use the `AES256` algorithm
    1. For `Generate Digital Signature Certificate`
        1. Generate the certificate on the device using the self-signed certificate
        1. For the signing algorithm select `ECCP384`
        1. For expiration date select one (1) year from today
1. Generate attestation certificates. This creates a certificate containing your newly created public key signed by Yubico’s built-in (and verifiable) keys. This proves that the Yubikey is genuine, as well as confirming the model, serial number etc.
    1. Download and install `yubico-piv-tool` [https://developers.yubico.com/yubico-piv-tool/Releases/](https://developers.yubico.com/yubico-piv-tool/Releases/)
    1. Create a new directory using your device serial number
        ```sh
        mkdir -p ./keys/<serial_num>/
        cd !$
        ```
    1. Read Yubikey PIV intermediate certificate in slot f9
        ```sh
        yubico-piv-tool --action=read-certificate --slot=f9 > SlotF9Intermediate.pem
        ```
    1. Read PIV attestation certificate for Digital Signature certificate in slot 9c
        ```sh
        yubico-piv-tool --action=attest --slot=9c > Slot9CAttestation.pem
        ```
    1. Save these files for archival after the signing ceremony ([Collect Archival Signing Ceremony Data](#collect-archival-signing-ceremony-data))

## Signing Ceremony

### Dry-run

Before performing the production TUF root signing ceremony, perform a dry-run to ensure that every key holder has all of the prerequisites completed and clearly understands the process.

- Signing event will be created at [https://github.com/docker/tuf-dev](https://github.com/docker/tuf-dev)
- Follow instructions at [Keyholder Root Signing](#keyholder-root-signing)

### Prerequisites

- Complete [Device Serial Verification](#device-serial-verification) and [Device Provisioning](#device-provisioning)
- Clone the GitHub repository [https://github.com/docker/tuf](https://github.com/docker/tuf)
- Complete the [TUF-on-CI signer setup instructions](https://github.com/theupdateframework/tuf-on-ci/blob/main/docs/SIGNER-SETUP.md)
- Designate someone to act as root signing lead
    - signing lead collects a comma separated list of all root key holder GitHub handles
    - Signing lead configures `~/.aws/config` for access to the Docker Image Signing - Production (654654578585) AWS account

### Procedure

#### Initialize TUF Repository
This section is to be completed by the root signing lead only.

1. The lead signs into Docker Image Signing - Production (654654578585) AWS account
1. The lead initializes the TUF signing ceremony by running the following command:
    ```sh
    tuf-on-ci-delegate sign/init
    ```
1. When prompted to configure root enter option 1 to configure signers
    ```sh
    Signing event sign/init (commit 85c7fc2)
    Creating a new TUF-on-CI repository
 
    Configuring role root
     1. Configure signers: [@mrjoelkamp], requiring 1 signatures
     2. Configure expiry: Role expires in 365 days, re-signing starts 60 days before expiry
    Please choose an option or press enter to continue: 1
    Please enter list of root signers [@mrjoelkamp]:
    ```
1. Paste the list of root key holder GitHub handles and press enter to continue
1. Enter the root threshold value of `3` and press enter
1. Press enter to continue again using the default settings for root expiration:
    ```sh
    Please choose an option or press enter to continue: 1
    Please enter list of root signers [@mrjoelkamp]: @mrjoelkamp, @kipz
    Please enter root threshold [1]: 3
     1. Configure signers: [@mrjoelkamp, @kipz], requiring 3 signatures
     2. Configure expiry: Role expires in 365 days, re-signing starts 60 days before expiry
    Please choose an option or press enter to continue
    ```
1. When prompted to configure targets select option 1 and paste the list of root key holder GitHub handles
1. Enter the targets threshold value of `3` and press enter
1. Press enter to continue again using the default settings for target expiration:
    ```sh
    Configuring role targets
     1. Configure signers: [@mrjoelkamp, @kipz], requiring 3 signatures
     2. Configure expiry: Role expires in 365 days, re-signing starts 60 days before expiry
    Please choose an option or press enter to continue:
    ```
1. When prompted to configure the online role, select option 1 to configure the online key
1. Enter option `4` for `AWS KMS`
1. Paste the production TUF AWS KMS online key id:
    ```sh
    arn:aws:kms:us-east-1:654654578585:key/751429f1-0aea-4bd8-b450-bb1bce6b058f
    ```
1. Select option `1` for `ECDSA_SHA_256`
1. Use defaults for timestamp and snapshot expiry:
    ```sh
     1. Configure online key: arn:aws:kms:us-east-1:654654578585:key/751429f1-0aea-4bd8-b450-bb1bce6b058f
     2. Configure timestamp: Expires in 2 days, re-signing starts 1 days before expiry
     3. Configure snapshot: Expires in 365 days, re-signing starts 60 days before expiry
    Please choose an option or press enter to continue:
    ```
1. Select `2` for Yubikey, insert Yubikey if not already inserted and enter PIN to sign:
    ```sh
    Configuring signing key
     1. Sigstore (OpenID Connect)
     2. Yubikey
    Please choose the type of signing key you would like to use [1]: 2
    Please insert your Yubikey and press enter:
    Your signature is required for role(s) {'targets'}.
 
    targets v1
     * Expiry period: 365 days, signing period: 60 days
    Enter pin to sign:
    Press enter to push changes to origin/sign/init:
    ```
1. Press enter to push changes to origin and initiate TUF repo

#### Keyholder Root Signing
This section is to be completed by all root key and targets key holders.

1. Each key holder opens the newly created signing event PR [https://github.com/docker/tuf/pulls](https://github.com/docker/tuf/pulls)
1. Copy the command to accept invite to join root
    ```sh
    tuf-on-ci-sign sign/init
    ```
1. Select `2` for Yubikey, insert Yubikey if not already inserted and enter PIN to sign
    ```sh
    Signing event sign/init (commit d28d253)
    Your signature is requested for role(s) {'root'}.
 
    root v1
     * Expiry period: 365 days, signing period: 60 days
     * New delegation root
       * Signers: 2/1 of ['@mrjoelkamp']
     * New delegation targets
       * Signers: 2/1 of ['@mrjoelkamp']
     * New online delegations timestamp & snapshot
       * Signers: 1/1 of ['awskms']
    Enter pin to sign:
    Press enter to push signature(s) to origin/sign/init:
    ```
1. Press enter to push changes to origin and complete sign-off of root and targets roles

#### Merge the Signing Event PR

1. Once every keyholder completes [Keyholder Root Signing](#keyholder-root-signing), merge the signing event PR to main
1. The signing ceremony is now complete

### Post-Ceremony

#### Collect Archival Signing Ceremony Data

1. Create a signing ceremony folder at [https://github.com/docker/tuf](https://github.com/docker/tuf) using the date of the signing ceremony (if one doesn't exist already):
    ```sh
    mkdir ./ceremony/YYYY-MM-DD/
    ```
1. Add each keyholder’s key data under a `keys/` directory using their device serial number using the data they generated in [Device Provisioning](#device-provisioning)
    ```sh
    ./ceremony/YYYY-MM-DD/keys/<serial_num>/SlotF9Intermediate.pem
    ./ceremony/YYYY-MM-DD/keys/<serial_num>/Slot9CAttestation.pem
    ```
1. Add a `README.md` with the device key data specifying the keyholder’s username:
    ```sh
    echo "held by: @username" > ./ceremony/YYYY-MM-DD/keys/<serial_num>/README.md
    ```
1. Update repo’s root `README.md` with a table including the username of each keyholder, the serial number of the device they used for the signing ceremony and their role.

#### Verify YubiKey Digital Signing Certificate Attestations

1. Follow [key verification instructions](https://github.com/docker/tuf/blob/main/tools/key-verification/README.md#how-to-verify-root-key-attestations)
1. Using the output of verified digital signature key attestations, verify that the `keys` defined in `root.json` match the public key output from the archived ceremony data.
