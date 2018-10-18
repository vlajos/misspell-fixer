FROM alpine:3.8
MAINTAINER Lajos Veres <vlajos@gmail.com>

RUN apk --no-cache add bash grep sed findutils coreutils diffutils

RUN mkdir /misspell-fixer

ADD misspell-fixer \
    README.md \
    /misspell-fixer/
ADD rules /misspell-fixer/rules
ADD lib /misspell-fixer/lib

WORKDIR /work

ENTRYPOINT ["/misspell-fixer/misspell-fixer"]
CMD ["-h"]