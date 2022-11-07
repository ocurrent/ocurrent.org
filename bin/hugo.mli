val build :
  commit:Current_git.Commit.t Current.t ->
  conf:Conf.t ->
  File.Copy.t list Current.t ->
  File.Index.t list ->
  File.Data.t list Current.t ->
  unit Current.t
(** [build ~commit files indexes data] builds the `hugo` website using the
    [files] that need to be copied, the [indexes] that must be created and, the
    [data] that needs to be exported. The build will be done in the repository
    point by [commit]. *)
