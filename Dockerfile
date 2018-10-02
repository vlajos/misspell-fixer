FROM alpine:3.8
MAINTAINER Lajos Veres <vlajos@gmail.com>

RUN apk --no-cache add bash grep sed findutils coreutils diffutils

RUN mkdir /misspell-fixer

ADD misspell-fixer \
    rules \
    README.md \
    /misspell-fixer/

WORKDIR /work

ENTRYPOINT ["/misspell-fixer/misspell-fixer"]
CMD ["-h"]