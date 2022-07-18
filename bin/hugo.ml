open Current.Syntax
module Cmd = Utils.Cmd

module Hugo = struct
  open Lwt.Infix

  type t = { files : File.Copy.t list; indexes : File.Index.t list }

  let id = "hugo-build"

  module Key = struct
    type t = { commit : Current_git.Commit.t }

    let to_json t =
      let commit = Current_git.Commit.hash t.commit in
      `Assoc [ ("commit", `String commit) ]

    let digest t = Yojson.Safe.to_string (to_json t)
    let pp f t = Fmt.pf f "%s" (Current_git.Commit.hash t.commit)
  end

  module Value = Current.Unit

  let folder_generator job path =
    let dir = fst (Fpath.split_base path) in
    Logs.debug (fun log -> log "Check  folder [%s]" (Fpath.to_string dir));
    match Bos.OS.Dir.create dir with
    | Ok true ->
        Logs.debug (fun log -> log "Create folder [%s]" (Fpath.to_string dir));
        Current.Job.log job "Create path (%s) in tmp dir." (Fpath.to_string dir)
    | Ok false ->
        Logs.debug (fun log -> log "Ignore folder [%s]" (Fpath.to_string dir));
        Current.Job.log job "Ignore path (%s) because it already exists."
          (Fpath.to_string dir)
    | Error (`Msg msg) -> failwith msg

  let write_all job dir files indexes =
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
    Lwt_list.iter_s i indexes

  let hugo ~cwd job =
    let output = Conf.Static.hugo_output in
    Current.Process.exec ~cwd ~job ~cancellable:true
      ("", [| "hugo"; "-d"; output; "-v" |])

  let deploy_over_git ~cwd ~job src commit =
    let open Lwt_result.Infix in
    let branch = Conf.Static.output_branch in
    let remote = Conf.Static.remote in
    let output = Conf.Static.hugo_output in
    let path = Fpath.add_seg src output in
    Git.init ~cwd ~job () >>= fun () ->
    Git.remote ~cwd ~job (`Add remote) >>= fun () ->
    Git.fetch ~cwd ~job (fst remote) branch >>= fun () ->
    Git.switch ~cwd ~job branch >>= fun () ->
    Git.rm_all ~cwd ~job () >>= fun () ->
    Cmd.copy_all ~cwd ~job path (Fpath.v ".") >>= fun () ->
    Git.add_all ~cwd ~job () >>= fun () ->
    let msg = Format.sprintf "Deploy %s" commit in
    Git.commit ~cwd ~job ~allow_empty:true msg >>= fun () ->
    Git.push ~cwd ~job ~force:true (fst remote) branch

  let build { files; indexes } job { Key.commit } =
    Current.Job.start job ~level:Current.Level.Average >>= fun () ->
    Current_git.with_checkout ~job commit @@ fun dir ->
    write_all job dir files indexes >>= fun () ->
    Lwt_result.bind (hugo ~cwd:dir job) (fun () ->
        let f cwd =
          let commit = Current_git.Commit.hash commit in
          deploy_over_git ~cwd ~job dir commit
        in
        Current.Process.with_tmpdir f)

  let pp f key = Fmt.pf f "@[<v2>Build Hugo with ocurrent.org#%a]" Key.pp key
  let auto_cancel = true
end

module Cache_hugo = Current_cache.Make (Hugo)

let build ~commit files indexes : unit Current.t =
  Current.component "build-with-hugo"
  |> let> commit = commit and> files = files in
     Cache_hugo.get { files; indexes } { Hugo.Key.commit }