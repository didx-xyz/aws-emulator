FROM public.ecr.aws/amazonlinux/amazonlinux:2023-minimal

RUN microdnf install -y shadow-utils \
    && useradd --system --create-home --home-dir /home/emulator --shell /sbin/nologin emulator \
    && microdnf remove -y shadow-utils && microdnf clean all \
    && mkdir -p /home/emulator/.aws/emulator && chown -R 999:999 /home/emulator/.aws/emulator

RUN curl -fsSL -o /tmp/aws-emulator.rpm \
    "https://downloads.aws.com/aws-emulator/packages/aws-emulator/LTS/latest/aws-emulator-$(uname -m).rpm" \
    && rpm -i /tmp/aws-emulator.rpm && rm /tmp/aws-emulator.rpm

USER emulator
WORKDIR /home/emulator

VOLUME ["/home/emulator/.aws/emulator"]

ENV HOME=/home/emulator \
    EMULATOR_BIND_ADDRESS=0.0.0.0 \
    EMULATOR_DATA_PORT=9297 \
    EMULATOR_TELEMETRY=off \
    RUST_LOG=info

HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=3 \
    CMD curl -fsSk -o /dev/null "https://127.0.0.1:${EMULATOR_DATA_PORT}/__admin/health" || exit 1

ENTRYPOINT ["aws-emulator"]
