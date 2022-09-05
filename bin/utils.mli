module Cmd : sig
  (** This module is a wrapper for command you would expect to execute from the
      command line. *)

  val copy_all :
    ?cwd:Fpath.t ->
    job:Current.Job.t ->
    Fpath.t ->
    Fpath.t ->
    unit Current.or_error Lwt.t
  (** [copy_all ~cwd ~job src dst] executes a [cp -a src/* dst/] from [cwd].
      [job] is a reference to an {!Current.t} job with whom the action is linked
      to. *)
end

module Yaml : sig
  (** This module gives helper functions to manipulate yaml files.

      All the functions in it raise {!Invalid_argument}. *)

  val access : field:string -> Yaml.value -> Yaml.value
  (** [access ~field yaml] returns a value associated with an object such as:

      {[
        title: The Hitchhiker's Guide to the Galaxy
        name: Douglas Adams
      ]}

      where [access ~field:"title" yaml] will return an object with [title] and
      [name] values. *)

  val access_str : field:string -> Yaml.value -> string
  (** [access_str ~field yaml] returns a string associated with an object such
      as:

      {[
        title: The Hitchhiker's Guide to the Galaxy
        name: Douglas Adams
      ]}

      where [access_str ~field:"title" yaml] will return the string "The
      Hitchhiker's Guide to the Galaxy". *)

  val access_array : field:string -> (Yaml.value -> 'a) -> Yaml.value -> 'a list
  (** [access_array ~field f yaml] returns a string associated with an object
      such as:

      {[
        - title: The Hitchhiker's Guide to the Galaxy
          name: Douglas Adams
        - title: I, Robot
          name: Isaac Asimov
      ]}

      where [access_array ~field:"book" ~f yaml] will return an object in the
      format required by the [f] function. *)

  val access_str_array : field:string -> Yaml.value -> string list
  (** [access_str_array ~field yaml] is the same as {!access_array} but with a
      string parsing. *)

  val parse_file : Fpath.t -> Yaml.value
  (** [parse_file path] returns in memory representation of the [yaml] file
      point by [path]. *)
end
