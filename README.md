# TUF

Docker's production [TUF](https://theupdateframework.io/) repository generated
using [TUF-on-CI](https://github.com/theupdateframework/tuf-on-ci).

The TUF metadata can be found in the [`metadata`](./metadata/) directory.

The TUF targets can be found under the [`targets`](./targets/) directory. The
TUF targets for
[Docker Official Images (DOI)](https://docs.docker.com/trusted-content/official-images/),
specifically the policies used to verify DOI, can be found in the
[`targets/doi`](./targets/doi/) directory.

## Signing Ceremony

The process used to establish Docker's production TUF root is documented in
[CEREMONY.md](./ceremony/CEREMONY.md).

## Keys

| Keyholder Name   | Keyholder GitHub ID                                             | Role                             | Serial Number                                    |
| ---------------- | --------------------------------------------------------------- | -------------------------------- | ------------------------------------------------ |
| Jean Laurent     | [jeanlaurent](https://github.com/jeanlaurent)                   | Root                             | [28751288](./ceremony/2024-06-04/keys/28751288/) |
| Alex Hokanson    | [ingshtrom](https://github.com/ingshtrom)                       | Root                             | [25515142](./ceremony/2024-06-04/keys/25515142/) |
| Brett Inman      | [binman-docker](https://github.com/binman-docker)               | Root                             | [25515991](./ceremony/2024-06-04/keys/25515991/) |
| Christian Dupuis | [cdupuis](https://github.com/cdupuis)                           | Root                             | [25599865](./ceremony/2024-06-04/keys/25599865/) |
| Rachel Taylor    | [rachel-taylor-docker](https://github.com/rachel-taylor-docker) | Root                             | [25515264](./ceremony/2024-06-04/keys/25515264/) |
| Laurent Goderre  | [LaurentGoderre](https://github.com/LaurentGoderre)             | Delegated Targets (DOI)          | [25515985](./ceremony/2024-06-04/keys/25515985/) |
| Tianon Gravi     | [tianon-sso](https://github.com/tianon-sso)                     | Delegated Targets (DOI)          | [25515137](./ceremony/2024-06-04/keys/25515137/) |
| Joseph Ferguson  | [yosifkit](https://github.com/yosifkit)                         | Delegated Targets (DOI)          | [25515267](./ceremony/2024-06-04/keys/25515267/) |
| Joel Kamp        | [mrjoelkamp](https://github.com/mrjoelkamp)                     | Targets, Delegated Targets (DOI) | [25515139](./ceremony/2024-06-04/keys/25515139/) |
| David Dooling    | [whalelines](https://github.com/whalelines)                     | Targets, Delegated Targets (DOI) | [25515003](./ceremony/2024-06-04/keys/25515003/) |
| James Carnegie   | [kipz](https://github.com/kipz)                                 | Targets, Delegated Targets (DOI) | [28751259](./ceremony/2024-06-04/keys/28751259/) |
| Jonny Stoten     | [jonnystoten](https://github.com/jonnystoten)                   | Targets, Delegated Targets (DOI) | [28751258](./ceremony/2024-06-04/keys/28751258/) |

## Verifying

To verify the TUF root key attestations, see
[key verification README](./tools/key-verification/README.md).

## Security reporting

If you have any security concerns please follow [SECURITY.md](./SECURITY.md)
