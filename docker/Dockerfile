FROM alpine:3.8
MAINTAINER Lajos Veres <vlajos@gmail.com>

RUN apk --no-cache add bash grep sed findutils coreutils diffutils

RUN mkdir /misspell-fixer

ADD misspell-fixer \
    misspell-fixer-not-so-safe.sed \
    misspell-fixer-safe.0.sed \
    misspell-fixer-safe.1.sed \
    misspell-fixer-safe.2.sed \
    misspell-fixer-safe.3.sed \
    misspell-fixer-gb-to-us.sed \
    README.md \
    /misspell-fixer/

WORKDIR /work

ENTRYPOINT ["/misspell-fixer/misspell-fixer"]
CMD ["-h"]