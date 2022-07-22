type t
(** Abstract type to represent the configuration *)

val output : t -> Current_github.Repo_id.t * string
(** [output t] gives the repository and the branch associated to the output
    repository where the website will be built. *)

val repos : t -> (Current_github.Repo_id.t * File.Copy.info list) list
(** [repos t] returns, for each repository, the files tracked into this
    repository. This files are going to be copied into the base skeleton. For
    more information about the vocabulary, see {!Pipeline}. *)

val indexes : t -> File.Index.t list
(** [indexes t] returns the list of paths where to create an [_index.md] into
    the the base skeleton. For more information about the vocabulary, see
    {!Pipeline}.*)

val load : Current_git.Commit.t Current.t -> t Current.t
(** [load commit] extracts the configuration from a commit on a specific
    repository. *)

val github_remote : t -> string * string
(** [git_remote t] returns a tuple with the remote url and the branch to push on
    github with ssh. *)

module Static : sig
  val hugo_output : string
  (** The path to where hugo should output the build files. *)

  val remote_name : string
  (** The name of the remote to add to git. *)
end
