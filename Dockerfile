FROM alpine:3.8
MAINTAINER Lajos Veres <vlajos@gmail.com>

RUN apk --no-cache add bash grep sed findutils coreutils diffutils

RUN mkdir /misspell-fixer

RUN echo '#!/usr/bin/env bash' >>/misspell-fixer/misspell-fixer-docker.sh
RUN echo '/misspell-fixer/misspell-fixer "$@"  /work' >>/misspell-fixer/misspell-fixer-docker.sh
RUN chmod a+x /misspell-fixer/misspell-fixer-docker.sh

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

ENTRYPOINT ["/misspell-fixer/misspell-fixer-docker.sh"]
CMD ["-h"]