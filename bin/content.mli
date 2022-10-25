val fetch :
  repo:string ->
  commit:Current_git.Commit.t Current.t ->
  File.Copy.info list ->
  File.Copy.t list Current.t
(** [fetch ~repo ~commit files] extracts files from a repository [repo], pinned
    at a certain [commit]. They are returned with their content as a list of
    {!File.Copy.t}. *)

val store :
  repo:string ->
  commit:Current_git.Commit.t Current.t ->
  File.Data.info list ->
  File.Data.t list Current.t
(** [store ~repo ~commit data] stores the data from a repository [repo], pinned
    at a certain [commit] in a temporary place. It returns their temporary
    location as a list of {!File.Data.t}. *)

val with_close_store : (unit -> 'a Lwt.t) -> 'a Lwt.t
(** [with_close_store fn] ensures the store is freed after the function [fn]
    runs. *)
