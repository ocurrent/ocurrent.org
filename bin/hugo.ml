open Current.Syntax
module Cmd = Utils.Cmd

module Hugo = struct
  open Lwt.Infix

  type t = {
    files : File.Copy.t list;
    indexes : File.Index.t list;
    data : File.Data.t list;
    conf : Conf.t;
  }

  let id = "hugo-build"

  module Key = struct
    type t = { commit : Current_git.Commit.t; digest : Digest.t }

    let to_json t =
      let commit = Current_git.Commit.hash t.commit in
      let digest = t.digest in
      `Assoc [ ("commit", `String commit); ("digest", `String digest) ]

    let digest t = Yojson.Safe.to_string (to_json t)
    let pp f t = Fmt.pf f "%s" (Current_git.Commit.hash t.commit)
  end

  module Value = Current.Unit

  let folder_generator job path =
    let dir = fst (Fpath.split_base path) in
    Logs.debug (fun log -> log "Check  folder [%s]" (Fpath.to_string dir));
    match Bos.OS.Dir.create dir with
    | Ok true ->
        Logs.debug (fun log -> log "Create folder [%a]" Fpath.pp dir);
        Current.Job.log job "Create path (%a) in tmp dir." Fpath.pp dir
    | Ok false ->
        Logs.debug (fun log -> log "Ignore folder [%a]" Fpath.pp dir);
        Current.Job.log job "Ignore path (%a) because it already exists."
          Fpath.pp dir
    | Error (`Msg msg) -> failwith msg

  let write_all job dir files indexes data =
    let f file =
      let path = Fpath.append dir (Fpath.v (File.Copy.destination file)) in
      folder_generator job path;
      Current.Job.log job "Create file [%s]" (Fpath.to_string path);
      File.Copy.write file ~dir
    in
    Lwt_list.iter_s f files >>= fun () ->
    let i index =
      let path = Fpath.append dir (File.Index.destination index) in
      folder_generator job path;
      Current.Job.log job "Create index [%s]" (Fpath.to_string path);
      File.Index.write index ~dir
    in
    Lwt_list.iter_s i indexes >>= fun () ->
    let d data =
      let path = Fpath.append dir (Fpath.v (File.Data.destination data)) in
      folder_generator job path;
      Current.Job.log job "Create data [%s]" (Fpath.to_string path);
      File.Data.export data ~dir
    in
    Content.with_close_store (fun () -> Lwt_list.iter_s d data)

  let hugo ~cwd job =
    let output = Conf.Static.hugo_output in
    Current.Process.exec ~cwd ~job ~cancellable:true
      ("", [| "hugo"; "-d"; output; "-v" |])

  let deploy_over_git ~cwd ~job ~conf src commit =
    let open Lwt_result.Infix in
    let remote, branch = Conf.github_remote conf in
    let remote_name = Conf.Static.remote_name in
    let output = Conf.Static.hugo_output in
    let path = Fpath.add_seg src output in
    Git.init ~cwd ~job () >>= fun () ->
    Git.remote ~cwd ~job (`Add (remote_name, remote)) >>= fun () ->
    Git.fetch ~cwd ~job ~depth:1 remote_name branch >>= fun () ->
    Git.switch ~cwd ~job branch >>= fun () ->
    Git.rm_all ~cwd ~job () >>= fun () ->
    Cmd.copy_all ~cwd ~job path (Fpath.v ".") >>= fun () ->
    Git.add_all ~cwd ~job () >>= fun () ->
    let msg = Printf.sprintf "Deploy %s" commit in
    Git.commit ~cwd ~job ~allow_empty:true msg >>= fun () ->
    Git.push ~cwd ~job ~force:true remote branch

  let build { files; indexes; conf; data } job { Key.commit; _ } =
    Current.Job.start job ~level:Current.Level.Average >>= fun () ->
    Current_git.with_checkout ~job commit @@ fun dir ->
    write_all job dir files indexes data >>= fun () ->
    Lwt_result.bind (hugo ~cwd:dir job) (fun () ->
        let f cwd =
          let commit = Current_git.Commit.hash commit in
          deploy_over_git ~cwd ~job ~conf dir commit
        in
        Current.Process.with_tmpdir f)

  let pp f key = Fmt.pf f "@[<v2>Build Hugo with ocurrent.org#%a]" Key.pp key
  let auto_cancel = true
end

module Cache_hugo = Current_cache.Make (Hugo)

let digest files indexes =
  let files =
    let f x = Yojson.Safe.to_string (File.Copy.to_yojson x) in
    List.map f files
  in
  let indexes =
    let f x = Yojson.Safe.to_string (File.Index.to_json x) in
    List.map f indexes
  in
  let to_digest = String.concat "," (files @ indexes) in
  let digest = Digest.string to_digest |> Digest.to_hex in
  Logs.info (fun l -> l "File digest: %s" digest);
  digest

let build ~commit ~conf files indexes data : unit Current.t =
  Current.component "build-with-hugo"
  |> let> commit = commit and> files = files and> data = data in
     let digest = digest files indexes in
     Cache_hugo.get
       { files; indexes; conf; data }
       { Hugo.Key.commit; Hugo.Key.digest }
