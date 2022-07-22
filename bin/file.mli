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
  val v : title:string -> description:string -> dst:Fpath.t -> unit -> t
  val write : t -> dir:Fpath.t -> unit Lwt.t
end
