FROM homebrew/brew:4.4.22

# ENV GOMERGE_VERSION=3.4.0

RUN brew tap Cian911/gomerge && \
    brew install gomerge
# specifying version not possible
# @${GOMERGE_VERSION}

ENTRYPOINT ["gomerge"]
CMD ["-h"]
