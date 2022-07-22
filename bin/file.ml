module Writer = struct
  let raw_write ~path content =
    Logs.debug (fun log -> log "Write page at %s" path);
    Lwt_io.with_file ~mode:Output path (fun output ->
        Lwt_stream.of_list content |> Lwt_io.write_lines output)
end

module Copy = struct
  type info = {
    title : string;
    summary : string;
    src : string;
    dst : string;
    authors : string list;
  }
  [@@deriving yojson]

  type t = { metadata : info; content : string list } [@@deriving yojson]

  open Lwt.Syntax

  let v ~title ?(summary = "") ~src ~dst ~authors () =
    let src = Fpath.normalize src |> Fpath.to_string in
    let dst = Fpath.normalize dst |> Fpath.to_string in
    { title; summary; src; dst; authors }

  let compare t1 t2 = String.compare t1.metadata.title t2.metadata.title
  let source t = t.metadata.src
  let destination t = t.metadata.dst

  let fetch_from path =
    let path = Fpath.to_string path in
    Lwt_io.with_file ~flags:[ Unix.O_RDONLY ] ~mode:Input path (fun input ->
        Lwt_io.read_lines input |> Lwt_stream.to_list)

  let read metadata ~dir =
    let path = Fpath.append dir (Fpath.v metadata.src) in
    let+ content = fetch_from path in
    { metadata; content }

  let format_with_header file =
    [
      "---";
      Format.sprintf "title: %s" file.metadata.title;
      Format.sprintf "summary: %s"
        (if file.metadata.summary = "" then "no summary"
        else file.metadata.title);
      Format.sprintf "authors: %s" (String.concat ", " file.metadata.authors);
      "---";
    ]
    @ file.content

  let write file ~dir =
    let path =
      Fpath.append dir (Fpath.v file.metadata.dst) |> Fpath.to_string
    in
    let page = format_with_header file in
    Writer.raw_write ~path page
end

module Index = struct
  type t = { title : string; summary : string; dst : Fpath.t }

  let of_json : Yojson.Safe.t -> t = function
    | `Assoc
        [
          ("title", `String title);
          ("summary", `String summary);
          ("dst", `String dst);
        ] ->
        let dst = Fpath.v dst in
        { title; summary; dst }
    | _ -> invalid_arg "Unable to parse the JSON for Index."

  let to_json t : Yojson.Safe.t =
    `Assoc
      [
        ("title", `String t.title);
        ("summary", `String t.summary);
        ("dst", `String (Fpath.to_string t.dst));
      ]

  let v ~title ~summary ~dst () =
    let dst = Fpath.normalize dst in
    { title; summary; dst }

  let destination index = index.dst

  let write index ~dir =
    let path = Fpath.add_seg index.dst "_index.md" in
    let path = Fpath.append dir path |> Fpath.to_string in
    let page =
      [
        "---";
        Format.sprintf "title: %s" index.title;
        Format.sprintf "summary: %s" index.summary;
        "---";
      ]
    in
    Writer.raw_write ~path page
end
