from alpine as build-environment
ARG BUILDPLATFORM
ARG TARGETARCH
WORKDIR /opt
RUN apk add clang lld curl build-base linux-headers \
    && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > rustup.sh \
    && chmod +x ./rustup.sh \
    && ./rustup.sh -y
WORKDIR /opt/foundry
COPY . .
RUN source $HOME/.profile && cargo build --release --target $TARGETARCH \
    && strip /opt/foundry/target/release/forge \
    && strip /opt/foundry/target/release/cast

from --platform=$TARGETPLATFORM alpine as foundry-client
ENV GLIBC_KEY=https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
ENV GLIBC_KEY_FILE=/etc/apk/keys/sgerrand.rsa.pub
ENV GLIBC_RELEASE=https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r0/glibc-2.35-r0.apk

RUN apk add linux-headers gcompat
RUN wget -q -O ${GLIBC_KEY_FILE} ${GLIBC_KEY} \
    && wget -O glibc.apk ${GLIBC_RELEASE} \
    && apk add glibc.apk --force
COPY --from=build-environment /opt/foundry/target/release/forge /usr/local/bin/forge
COPY --from=build-environment /opt/foundry/target/release/cast /usr/local/bin/cast
ENTRYPOINT ["/bin/sh -c"]