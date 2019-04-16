FROM elixir:1.6.5-alpine

RUN apk add --no-cache \
    curl \
    gawk \
    build-base \
    git

RUN mkdir -p /src/vault_certificate_issuer
WORKDIR /src/vault_certificate_issuer

ADD mix.exs /src/vault_certificate_issuer
ADD mix.lock /src/vault_certificate_issuer
RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get
RUN MIX_ENV=prod mix deps.compile --env=prod

ADD . /src/vault_certificate_issuer/
RUN MIX_ENV=prod mix compile --env=prod
RUN MIX_ENV=prod mix release --env=prod

FROM alpine:3.8

RUN apk add --no-cache bash ncurses-libs libcrypto1.0 tzdata

RUN mkdir -p /vault_certificate_issuer /tmp
WORKDIR /vault_certificate_issuer

COPY --from=0 /src/vault_certificate_issuer/_build/prod/rel/vault_certificate_issuer/releases/latest/vault_certificate_issuer.tar.gz /tmp/
RUN tar xvzf /tmp/vault_certificate_issuer.tar.gz
RUN rm -f /tmp/vault_certificate_issuer.tar.gz

VOLUME /tmp/cert/

ENV SOCKET_PATH /tmp/cert/certs.sock
ENV VAULT_URL http://vault:8200

CMD [ "/vault_certificate_issuer/bin/vault_certificate_issuer", "foreground" ]
