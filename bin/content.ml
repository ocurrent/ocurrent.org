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
    let f acc file =
      let+ file = File.Copy.read ~dir file in
      logs repo file;
      file :: acc
    in
    Lwt_list.fold_left_s f [] files

  let build files job { Key.commit; Key.repo; _ } =
    Current.Job.start job ~level:Current.Level.Average >>= fun () ->
    Git.with_checkout ~job commit @@ fun dir ->
    extract ~job ~dir repo files >>= Lwt_result.return

  let pp f key = Fmt.pf f "@[<v2>Fetch files for %a@]" Key.pp key
  let auto_cancel = true
end

module Cache_docs = Current_cache.Make (Content)

let fetch ~repo ~commit files =
  Current.component "fetch-doc"
  |> let> commit = commit in
     let digest =
       let f x = Yojson.Safe.to_string (File.Copy.info_to_yojson x) in
       List.map f files |> String.concat "," |> Digest.string |> Digest.to_hex
     in
     let cache : File.Copy.t list Current.Primitive.t =
       Cache_docs.get files
         { Content.Key.repo; Content.Key.commit; Content.Key.digest }
     in
     cache
