(lang dune 3.3)
(generate_opam_files true)

(name ocurrentorg)

(package
  (name ocurrentorg)
  (source (github ocurrent/ocurrent.org))
  (license ISC)
  (authors "OCurrent team")
  (maintainers "OCurrent team")
  (synopsis "Nope")
  (description "Nope")
  (depends
    (dune (>= 3.3))
    (cmdliner (>= 1.1.0))
    (current (>= 0.6.2))
    (current_git (>= 0.6.2))
    (current_github (>= 0.6.2))
    (current_docker (>= 0.6.2))
    (current_web (>= 0.6.2))
    (yaml (>= 3.1.0))
    (bos (>= 0.2.1))
    yojson
    ppx_deriving_yojson
    (prometheus-app (>= 1.2))
  )
)
