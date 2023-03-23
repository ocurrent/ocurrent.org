val v :
  ?channel:Current_slack.channel ->
  branch:string ->
  app:Current_github.App.t ->
  unit ->
  unit Current.t
(** [v ?channel ~branch ~app ()] create a pipeline to give to a
    {!Current.Engine}. The config is extracted from the [app] on [branch]. [app]
    is the credential for the GitHub App that monitors the repository. If
    [channel] is provided, it will push the status for each build on slack. *)
