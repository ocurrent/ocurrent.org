FROM ocaml/opam:alpine-3.15-ocaml-4.14@sha256:7004b4b0443758ff0830c39a1af02090430e58890fc1f9e58433844ebd61d4d1 AS build
COPY --chown=opam ./ocurrentorg.opam /src/ocurrentorg/
RUN cd ~/opam-repository && git fetch origin -q master && git reset --hard 97da9a1b68b824a65a09e5f7d071fcf2da35bd1b && opam update
RUN sudo apk update && sudo apk add gmp-dev graphviz libev-dev libffi-dev sqlite-dev
WORKDIR /src/ocurrentorg
RUN opam-2.1 install . -y --deps-only
COPY --chown=opam ./bin/* ./dune-project /src/ocurrentorg/
RUN opam-2.1 exec -- dune build _build/install/default/bin/watcher

FROM alpine:edge
RUN apk update && apk add dumb-init git graphviz libev sqlite-dev gmp openssh hugo
COPY --from=build /src/ocurrentorg/_build/install/default/bin/watcher /usr/local/bin/website-watcher
RUN mkdir -p "/root/.ssh"
RUN echo -e "HostName github.com\n    User git\n    IdentityFile /run/secrets/ocurrentorg-ssh" >> "/root/.ssh/config"
RUN echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config
RUN git config --global user.email "contact@tarides.com"
RUN git config --global user.name "Tarides Pipeline"
EXPOSE 8080
ENTRYPOINT [ "dumb-init", "website-watcher" ]
