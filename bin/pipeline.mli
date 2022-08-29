val v : branch:string -> app:Current_github.App.t -> unit -> unit Current.t
(** [v ~branch ~app ()] create a pipeline to give to a {!Current.Engine}. The
    config is extracted from the [app] on [branch]. [app] is the credential for
    the GitHub App that monitors the repository. *)
