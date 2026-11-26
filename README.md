# aws-emulator

This repo builds and publishes a multi-arch (amd64, arm64) Docker image of AWS Emulator to GitHub Container Registry, because AWS does not publish a prebuilt image.

## AWS resources

- [AWS Emulator source](https://github.com/aws/aws-emulator)
- [AWS Emulator documentation](https://docs.aws.amazon.com/emulator/)
- [Getting started with Docker](https://docs.aws.amazon.com/emulator/latest/userguide/getting-started-docker.html)
- [AWS Emulator product page](https://aws.amazon.com/products/developer-tools/emulator/)

## Image

The image is `ghcr.io/didx-xyz/aws-emulator`.

| Tag                       | Meaning                                          |
| ------------------------- | ------------------------------------------------ |
| `latest`                  | Latest daily or manual rebuild.                  |
| `lts`                     | Same build as `latest`.                          |
| `YYYYMMDD`                | Rebuild date, for example `20261126`.            |
| `lts-YYYYMMDD`            | Same build as `YYYYMMDD`.                        |
| `master`                  | Latest push to `master`.                         |
| `master-<short sha>`      | Build of one commit pushed to `master`.          |
| `pr-<number>`             | Latest build of a pull request.                  |
| `pr-<number>-<short sha>` | Build of one commit in a pull request.           |

The image rebuilds every day at 04:00 UTC with the latest LTS release from AWS. `pr-*` tags are deleted 7 days after push.

## Quick start

```bash
docker run --rm --memory=2g --memory-swap=2g -p 127.0.0.1:9297:9297 \
  -v emulator:/home/emulator/.aws/emulator \
  ghcr.io/didx-xyz/aws-emulator:lts
```

Always bind the port to `127.0.0.1`. Without the address, Docker opens the emulator to your whole network. The memory limit matches the AWS docs. If the container goes over it, the container stops and you lose the emulated resources.

The image:

- Runs as the non-root `emulator` user with `HOME=/home/emulator`.
- Listens on the port in `EMULATOR_DATA_PORT`, which defaults to `9297`.
- Turns telemetry off with `EMULATOR_TELEMETRY=off`.
- Writes credentials and the certificate to `/home/emulator/.aws/emulator/<port>/`.

## Demo with Docker Compose

```bash
docker compose up
```

[`compose.yaml`](compose.yaml) starts the emulator and an `aws-cli` container. The CLI container runs `aws sts get-caller-identity`, `aws s3 mb s3://demo`, and `aws s3 ls`.

The CLI container shares the emulator's network (`network_mode: service:aws-emulator`). The emulator's certificate matches `127.0.0.1`, and in a shared network `127.0.0.1:9297` reaches the emulator.

### Use the emulator from the host

While the emulator runs, copy its credentials and certificate out of the container:

```bash
docker compose cp aws-emulator:/home/emulator/.aws/emulator/9297/. ./emulator
```

Then set the environment variables from [Pointing your AWS SDK at AWS Emulator](https://docs.aws.amazon.com/emulator/latest/userguide/point-sdk-to-emulator.html) to the copied files:

```bash
export AWS_ENDPOINT_URL=https://127.0.0.1:9297
export AWS_SHARED_CREDENTIALS_FILE=$PWD/emulator/emulator_credentials
export AWS_CONFIG_FILE=$PWD/emulator/config
export AWS_CA_BUNDLE=$PWD/emulator/ca.pem
export AWS_EC2_METADATA_DISABLED=true
export AWS_DISABLE_HOST_PREFIX_INJECTION=true
export AWS_REGION=us-east-1
export AWS_DEFAULT_REGION=us-east-1
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE
```

The emulator creates new credentials and a new certificate each time it starts. Copy the files again after a restart. To check that you reach the emulator, run `aws sts get-caller-identity`. The account ID is `000000000000`.

## Fork this repo

The Docker workflow derives the image name from the repository (`ghcr.io/<owner>/<repo>`), so a fork publishes to its own namespace without edits.

1. Enable GitHub Actions on the fork.
2. Make sure the `GITHUB_TOKEN` can write packages. The workflow requests `packages: write` itself, and this is the default for a repository's own workflows.
3. If your default branch is not `master`, change the `push` branch filter in [`.github/workflows/docker.yml`](.github/workflows/docker.yml).

## Dependency updates

Dependabot checks GitHub Actions weekly and updates the actions that the workflows pin to commit SHAs.

## License

[CC0 1.0 Universal](LICENSE).
