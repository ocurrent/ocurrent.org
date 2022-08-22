---
title: "Build\_matrix"
summary: "Builds on multiple compiler versions"
path: "/examples/02"
image: "/examples/example2.svg"
---

[build_matrix.ml][] contains a slightly more advanced pipeline:

![example2](/examples/example2.svg)

```ocaml
let weekly = Current_cache.Schedule.v ~valid_for:(Duration.of_day 7) ()

(* Run "docker build" on the latest commit in Git repository [repo]. *)
let pipeline ~repo () =
  let src = Git.Local.head_commit repo in
  let base = Docker.pull ~schedule:weekly "ocaml/opam2" in
  let build ocaml_version =
    let dockerfile =
      let+ base = base in
      dockerfile ~base ~ocaml_version
    in
    Docker.build ~label:ocaml_version ~pull:false ~dockerfile src |>
    Docker.tag ~tag:(Fmt.strf "example-%s" ocaml_version)
  in
  Current.all [
    build "4.07";
    build "4.08"
  ]
```

The `Docker.pull` step shows the use of a _schedule_. In this case, we consider
a pulled image to be valid for one week; after that OCurrent will automatically
run the `docker pull` again to check for newer versions.

It uses `Current.all` to build against different versions of OCaml, generating
a suitable Dockerfile for each version (the `ocaml/opam2` image contains multiple
versions of the compiler and the Dockerfile just selects one of them).

The generated images are then tagged with the compiler version used to build them.

[build_matrix.ml]: https://github.com/talex5/ocurrent/blob/master/examples/build_matrix.ml
