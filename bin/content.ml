open Current.Syntax
module Git_ext = Git
module Git = Current_git

module Content = struct
  open Lwt.Infix

  type t = File.Copy.info list

  let id = "get-files-contents"

  module Key = struct
    type t = { repo : string; commit : Git.Commit.t; digest : Digest.t }

    let to_json t =
      `Assoc
        [
          ("repository", `String t.repo);
          ("commit", `String (Git.Commit.hash t.commit));
          ("digest", `String t.digest);
        ]

    let digest t = Yojson.Safe.to_string (to_json t)
    let pp f t = Yojson.Safe.pretty_print f (to_json t)
  end

  module Value = struct
    type t = File.Copy.t list

    let marshal t =
      let json : Yojson.Safe.t =
        `List
          (List.sort File.Copy.compare t
          |> List.map (fun file -> File.Copy.to_yojson file))
      in
      Yojson.Safe.to_string json

    let unmarshal t =
      let convert_or_fail file =
        match File.Copy.of_yojson file with
        | Ok file -> file
        | Error err -> Fmt.failwith "Unable to unmarshal the json: %s" err
      in
      Yojson.Safe.from_string t
      |> Yojson.Safe.Util.to_list
      |> List.map convert_or_fail
  end

  let extract ~job ~dir repo files =
    let open Lwt.Syntax in
    let logs repo file =
      Current.Job.log job "Extracting content from %s/%s" repo
        (File.Copy.source file);
      Logs.info (fun log ->
          log "Docs reader: extracting content from %s/%s" repo
            (File.Copy.source file))
    in
    let f file =
      let+ file = File.Copy.read ~dir file in
      logs repo file;
      file
    in
    Lwt_list.map_s f files

  let build files job { Key.commit; Key.repo; _ } =
    Current.Job.start job ~level:Current.Level.Average >>= fun () ->
    Git.with_checkout ~job commit @@ fun dir ->
    extract ~job ~dir repo files >>= Lwt_result.return

  let pp f key = Fmt.pf f "@[<v2>Fetch files for %a@]" Key.pp key
  let auto_cancel = true
end

module Cache_docs = Current_cache.Make (Content)

let weekly = Current_cache.Schedule.v ~valid_for:(Duration.of_day 7) ()

let fetch ~repo ~commit files =
  Current.component "fetch-doc"
  |> let> commit = commit in
     let digest =
       let f x = Yojson.Safe.to_string (File.Copy.info_to_yojson x) in
       List.map f files |> String.concat "," |> Digest.string |> Digest.to_hex
     in
     let cache : File.Copy.t list Current.Primitive.t =
       Cache_docs.get ~schedule:weekly files
         { Content.Key.repo; Content.Key.commit; Content.Key.digest }
     in
     cache

module Store = struct
  open Lwt.Infix

  type t = File.Data.info list

  let id = "get-data"

  module Key = struct
    type t = { repo : string; commit : Git.Commit.t; date : float }

    let to_json t =
      `Assoc
        [
          ("repository", `String t.repo);
          ("commit", `String (Git.Commit.hash t.commit));
          ("date", `Float t.date);
        ]

    let digest t = Yojson.Safe.to_string (to_json t)
    let pp f t = Yojson.Safe.pretty_print f (to_json t)
  end

  module Value = struct
    type t = File.Data.t list

    let marshal t =
      let json : Yojson.Safe.t =
        `List
          (List.sort File.Data.compare t
          |> List.map (fun file -> File.Data.to_json file))
      in
      Yojson.Safe.to_string json

    let unmarshal t =
      Yojson.Safe.from_string t
      |> Yojson.Safe.Util.to_list
      |> List.map File.Data.of_json
  end

  let create_store repo =
    let open Lwt.Syntax in
    let root = Current.state_dir "store" in
    let path = Fpath.add_seg root repo in
    let+ () = Utils.Dir.ensure path in
    path

  let close_store () =
    let root = Current.state_dir "store" in
    Utils.Dir.delete root

  let store ~job ~tmp_dir ~dir repo data =
    let open Lwt.Syntax in
    let logs repo data =
      Current.Job.log job "Storing data for %s/%s" repo (File.Data.source data);
      Logs.info (fun log ->
          log "Data store: storing from %s/%s" repo (File.Data.source data))
    in
    let f data =
      let+ data = File.Data.store ~tmp_dir ~dir data in
      logs repo data;
      data
    in
    Lwt_list.map_s f data

  let build data job { Key.commit; Key.repo; _ } =
    Current.Job.start job ~level:Current.Level.Average >>= fun () ->
    Git.with_checkout ~job commit @@ fun dir ->
    create_store repo >>= fun tmp_dir ->
    Current.Job.log job "Trying to copy %s in %s" (Fpath.to_string dir)
      (Fpath.to_string tmp_dir);
    store ~job ~tmp_dir ~dir repo data >>= Lwt_result.return

  let pp f key = Fmt.pf f "@[<v2>Storing data for %a@]" Key.pp key
  let auto_cancel = true
end

module Cache_store = Current_cache.Make (Store)

let store ~repo ~commit data =
  Current.component "store-data"
  |> let> commit = commit in
     let date = Unix.time () in
     let cache =
       Cache_store.get ~schedule:weekly data Store.Key.{ repo; commit; date }
     in
     cache

let with_close_store fn = Lwt.finalize fn (fun () -> Store.close_store ())
