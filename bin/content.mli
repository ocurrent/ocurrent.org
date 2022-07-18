val fetch :
  repo:string ->
  commit:Current_git.Commit.t Current.t ->
  File.Copy.info list ->
  File.Copy.t list Current.t
(** [fetch ~repo ~commit files] extracts files with their content as a list of
    {!File.t} from a repository [repo], pinned at a certain [commit]. *)
