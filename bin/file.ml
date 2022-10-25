module Writer = struct
  let raw_write ~path content =
    Logs.debug (fun log -> log "Write page at %s" path);
    Lwt_io.with_file ~mode:Output path (fun output ->
        Lwt_stream.of_list content |> Lwt_io.write_lines output)
end

module Copy = struct
  open Lwt.Syntax

  let tz_of_date_time = Timedesc.Time_zone.make_exn "Europe/Paris"

  type info = {
    title : string;
    summary : string;
    src : string;
    dst : string;
    authors : string list;
    date : string;
  }
  [@@deriving yojson]

  type t = { metadata : info; content : string list } [@@deriving yojson]

  let v ~title ?(summary = "") ~src ~dst ~authors () =
    let date = Timedesc.(now ~tz_of_date_time () |> date |> Date.to_rfc3339) in
    let src = Fpath.(normalize src |> to_string) in
    let dst = Fpath.(normalize dst |> to_string) in
    { title; summary; src; dst; authors; date }

  let compare t1 t2 = String.compare t1.metadata.title t2.metadata.title
  let source t = t.metadata.src
  let destination t = t.metadata.dst

  let fetch_from path =
    let path = Fpath.to_string path in
    Lwt_io.with_file ~flags:[ Unix.O_RDONLY ] ~mode:Input path (fun input ->
        Lwt_io.read_lines input |> Lwt_stream.to_list)

  let read metadata ~dir =
    let path = Fpath.(append dir (v metadata.src)) in
    let+ content = fetch_from path in
    { metadata; content }

  let format_with_header file =
    [
      "---";
      Printf.sprintf "title: %s" file.metadata.title;
      Printf.sprintf "summary: %s"
        (if file.metadata.summary = "" then "no summary"
        else file.metadata.title);
      Printf.sprintf "authors: %s" (String.concat ", " file.metadata.authors);
      Printf.sprintf "date: %s" file.metadata.date;
      "---";
    ]
    @ file.content

  let write file ~dir =
    let path = Fpath.(append dir (v file.metadata.dst) |> to_string) in
    let page = format_with_header file in
    Writer.raw_write ~path page
end

module Index = struct
  type t = { title : string; description : string; dst : Fpath.t }

  let of_json : Yojson.Safe.t -> t = function
    | `Assoc
        [
          ("title", `String title);
          ("description", `String description);
          ("dst", `String dst);
        ] ->
        let dst = Fpath.v dst in
        { title; description; dst }
    | _ -> invalid_arg "Unable to parse the JSON for Index."

  let to_json t : Yojson.Safe.t =
    `Assoc
      [
        ("title", `String t.title);
        ("description", `String t.description);
        ("dst", `String (Fpath.to_string t.dst));
      ]

  let v ~title ~description ~dst =
    let dst = Fpath.normalize dst in
    { title; description; dst }

  let destination index = index.dst

  let write index ~dir =
    let path = Fpath.add_seg index.dst "_index.md" in
    let path = Fpath.(append dir path |> to_string) in
    let page =
      [
        "---";
        Printf.sprintf "title: %s" index.title;
        Printf.sprintf "description: %s" index.description;
        "---";
      ]
    in
    Writer.raw_write ~path page
end

module Data = struct
  open Lwt.Syntax

  type info = { src : Fpath.t; dst : Fpath.t }
  type t = { metadata : info; store_at : Fpath.t }

  let source store = store.metadata.src |> Fpath.to_string
  let destination store = store.metadata.dst |> Fpath.to_string

  let info_of_json : Yojson.Safe.t -> info = function
    | `Assoc [ ("src", `String src); ("dst", `String dst) ] ->
        let src = Fpath.v src in
        let dst = Fpath.v dst in
        { src; dst }
    | _ -> invalid_arg "Unable to parse the JSON for Data.info."

  let of_json = function
    | `Assoc
        [
          ("src", `String src);
          ("dst", `String dst);
          ("store_at", `String store_at);
        ] ->
        let src = Fpath.v src in
        let dst = Fpath.v dst in
        let store_at = Fpath.v store_at in
        { metadata = { src; dst }; store_at }
    | _ -> invalid_arg "Unable to parse the JSON for Data.t."

  let info_to_json t : Yojson.Safe.t =
    `Assoc
      [
        ("src", `String (Fpath.to_string t.src));
        ("dst", `String (Fpath.to_string t.dst));
      ]

  let to_json t =
    `Assoc
      [
        ("src", `String (Fpath.to_string t.metadata.src));
        ("dst", `String (Fpath.to_string t.metadata.dst));
        ("store_at", `String (Fpath.to_string t.store_at));
      ]

  let v ~src ~dst =
    let src = Fpath.normalize src in
    let dst = Fpath.normalize dst in
    { src; dst }

  let compare t1 t2 = Fpath.compare t1.store_at t2.store_at

  let store info ~tmp_dir ~dir =
    let name = Fpath.(normalize info.src |> basename) in
    let store_at = Fpath.add_seg tmp_dir name in
    let store = { metadata = info; store_at } in
    let src = Fpath.(append dir info.src) in
    let+ () = Utils.Cmd.move src store_at in
    store

  let export store ~dir =
    let dst = Fpath.(append dir store.metadata.dst) in
    Utils.Cmd.move store.store_at dst
end
