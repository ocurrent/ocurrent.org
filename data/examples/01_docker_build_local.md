---
title: "docker\_build\_local"
subtitle: "simple sequential pipeline"
path: "/examples/01"
image: "./example1.svg"
---

This monitors a local Git repository (`repo`), from which it gets the current
head commit. It copies it to a temporary clone and builds it with `docker build /path/to/clone`, then executes the example with `--help` to check that it runs.

```bash
$ git clone https://github.com/talex5/ocurrent.git
$ cd ocurrent/
$ dune exec -- ./examples/docker_build_local.exe .
[...]
    current [INFO] Evaluation complete:
                     Result: Pending
                     Watching: [/home/user/ocurrent/#refs/heads/master;
                                HEAD(/home/user/ocurrent/)]
[...]
current.docker [INFO] Build of docker image "build-of-d75e33fd875d80cd8e0cddf83904dd6d7aea12d3" succeeded
[...]
    current [INFO] Evaluation complete:
                     Result: Ok ()
                     Watching: [/home/user/ocurrent/#refs/heads/master;
                                HEAD(/home/user/ocurrent/)]
```

If you make a new commit or change branch (e.g. `git checkout -b test HEAD~1`) then OCurrent will
notice and build it again.

The example code above works mostly with values of type `'a Current.t`.
For example, `Docker.build` takes a source current and returns a Docker image current.
If you have a function that works on concrete values then you can use `Current.map`
(or the `let+` syntax) to make it work on currents instead.

You can also use `Current.bind` (or the `let*` syntax) if you can only decide
what the next part of the pipeline should be by looking at a concrete input.
However, using `bind` limits OCurrent's ability to analyse the pipeline,
because it must wait for the input to be ready before knowing what happens
next.

OCurrent has a small core language (in `lib` and `lib_term`), but most
functionality is added by external libraries. See the [plugins][] directory for
some examples.

The example also runs a minimal web UI on port 8080 (use `--port=...` to change it),
showing the state of the system. You will need to have [graphviz][] installed in order
to see the diagrams.

![example1](/example1.svg)

A green box indicates a pipeline stage that succeeded, orange means
in-progress, grey means cannot be started yet (inputs not ready),
yellow means queued or waiting for permission to start, and red means failed.

Clicking on a box shows the log for that operation (though not all operations
have logs; `head commit` doesn't, for example).

[docker_build_local.ml]: https://github.com/ocurrent/ocurrent/blob/master/doc/examples/docker_build_local.ml
[plugins]: https://github.com/ocurrent/ocurrent/blob/master/plugins
[graphviz]: https://graphviz.org/
