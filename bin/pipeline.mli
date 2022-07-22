val v :
  repo:Current_github.Repo_id.t ->
  branch:string ->
  github:Current_github.Api.t ->
  unit ->
  unit Current.t
(** [v ~repo ~branch ~github ()] create a pipeline to give to a
    {!Current.Engine}. The config is extracted from the [repo] on [branch].
    [github] is the value of the indentification extracted from a token. *)
