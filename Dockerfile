FROM alpine:3.8 as builder

ARG VERSION

ENV GOPATH /go

RUN apk --no-cache add \
  dep \
  git \
  go \
  libc-dev \
  make

WORKDIR /go/src/github.com/cloudflare

RUN git clone https://github.com/cloudflare/cfssl.git

WORKDIR /go/src/github.com/cloudflare/cfssl

RUN git reset --hard ${VERSION}
RUN dep ensure
RUN make

FROM alpine:3.8

LABEL maintainer="Joshua Rutherford <joshua.rutherfor@deciphernow.com>"

ENV CFSSL_CA_CERTIFICATE ""
ENV CFSSL_CA_KEY ""

COPY --from=0 /go/src/github.com/cloudflare/cfssl/bin /usr/local/bin
COPY files/ /

RUN chown -R 0:0 /etc/cfssl
RUN chmod -R g=u /etc/cfssl

EXPOSE 8888
USER 1000
VOLUME /etc/cfssl/tls

ENTRYPOINT ["/usr/local/bin/entrypoint"]

CMD ["/usr/local/bin/cfssl", "serve", "-config", "/etc/cfssl/config.json", "-address", "0.0.0.0", "-port", "8888", "-ca", "/etc/cfssl/tls/ca.crt", "-ca-key", "/etc/cfssl/tls/ca.key"] 
