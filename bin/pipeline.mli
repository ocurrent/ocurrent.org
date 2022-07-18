val v : config:Conf.t -> github:Current_github.Api.t -> unit -> unit Current.t
(** [v ~config ~github ()] create a pipeline to give to a {!Current.Engine}. The
    config is extracted from the [yaml] configuration file. [github] is the
    value of the indentification extracted from a token. *)
