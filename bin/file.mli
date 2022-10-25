module Copy : sig
  type info [@@deriving yojson]
  type t [@@deriving yojson]

  val source : t -> string
  val destination : t -> string

  val v :
    title:string ->
    ?summary:string ->
    src:Fpath.t ->
    dst:Fpath.t ->
    authors:string list ->
    unit ->
    info

  val compare : t -> t -> int
  val read : info -> dir:Fpath.t -> t Lwt.t
  val write : t -> dir:Fpath.t -> unit Lwt.t
end

module Index : sig
  type t

  val destination : t -> Fpath.t
  val of_json : Yojson.Safe.t -> t
  val to_json : t -> Yojson.Safe.t
  val v : title:string -> description:string -> dst:Fpath.t -> t
  val write : t -> dir:Fpath.t -> unit Lwt.t
end

module Data : sig
  type info
  type t

  val source : t -> string
  val destination : t -> string
  val info_to_json : info -> Yojson.Safe.t
  val info_of_json : Yojson.Safe.t -> info
  val to_json : t -> Yojson.Safe.t
  val of_json : Yojson.Safe.t -> t
  val v : src:Fpath.t -> dst:Fpath.t -> info
  val compare : t -> t -> int
  val store : info -> tmp_dir:Fpath.t -> dir:Fpath.t -> t Lwt.t
  val export : t -> dir:Fpath.t -> unit Lwt.t
end
