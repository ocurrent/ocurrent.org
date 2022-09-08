val build :
  commit:Current_git.Commit.t Current.t ->
  conf:Conf.t ->
  File.Copy.t list Current.t ->
  File.Index.t list ->
  unit Current.t
(** [build ~commit files indexes] builds the `hugo` website using the [files]
    that need to be copied and the [indexes] that must be create. The build wil
    be done in the repository point by [commit]. *)
