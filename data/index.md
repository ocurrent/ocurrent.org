---
title: OCurrent
subtitle: a workflow specification language written in OCaml
---

OCurrent allows you to specify a workflow / pipeline for keeping things
up-to-date.

![Example OCurrent pipeline](./pipeline.svg)

For example, the pipeline shown about fetches the head of a GitHub repository's
`master` branch, builds it, runs the tests, and deploys the binary if the tests
pass. When a new commit is pushed, it runs the pipeline again.

```ocaml
let pipeline ~repo () =
  let src = Git.Local.head_commit repo in
  let base = Docker.pull ~schedule:weekly "ocaml/opam2" in
  let build ocaml_version =
    let dockerfile =
      let+ base = base in
      dockerfile ~base ~ocaml_version
    in
    Docker.build ~label:ocaml_version ~pull:false ~dockerfile (`Git src) |>
    Docker.tag ~tag:(Fmt.strf "example-%s" ocaml_version)
  in
  Current.all [
    build "4.07";
    build "4.08"
  ]
```

Another use might be to keep the GitHub build status of each PR in your Git
repository showing the result of fetching, building and testing the PR's head
commit. If the head commit changes, the result must be recalculated.

An OCurrent pipeline is written using an OCaml eDSL. When OCurrent evaluates it,
it records the inputs used (e.g. the current set of open PRs and the head of
each one), monitors them, and automatically recalculates when an input changes.

The [OCurrent wiki] contains documentation and examples. In particular, you
might like to start by reading about the [example pipelines] or how to [write
your own plugins][writing-plugins].

Larger uses of OCurrent include the [OCaml Docker base image
builder][docker-base-images] and the CI that tests this repository itself.

# Licensing

OCurrent is licensed under the Apache License, Version 2.0.

[docker-base-images]: https://github.com/ocaml-ci/docker-base-images
[writing-plugins]: https://github.com/ocaml-ci/ocurrent/wiki/Writing-plugins
[example pipelines]: https://github.com/ocaml-ci/ocurrent/wiki/Example-pipelines
[ocurrent wiki]: https://github.com/ocaml-ci/ocurrent/wiki
[license]: ./LICENSE
