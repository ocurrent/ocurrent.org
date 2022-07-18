type t
(** Abstract type to represent the configuration *)

val base : t -> Current_github.Repo_id.t * string
(** [base t] gives the repository and the branch associated to the content that
    will serve as a skeleton for building the website. *)

val repos : t -> (Current_github.Repo_id.t * File.Copy.info list) list
(** [repos t] returns, for each repository, the files tracked into this
    repository. This files are going to be copied into the [base] skeleton. For
    more information about the vocabulary, see {!Pipeline}. *)

val indexes : t -> File.Index.t list
(** [indexes t] returns the list of paths where to create an [_index.md] into
    the the [base] skeleton. For more information about the vocabulary, see
    {!Pipeline}.*)

val from_file : Fpath.t -> t
(** [from_file path] extracts the configuration from a file located at [path]. *)

module Static : sig
  val hugo_output : string
  (** The path to where hugo should output the build files. *)

  val output_branch : string
  (** The branch on which the deployement will be made. *)

  val remote : string * string
  (** The name and the Github ssh address of repository where the site will be
      pushed. *)
end
