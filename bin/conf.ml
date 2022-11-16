open Current.Syntax
module Gh = Current_github

type t = {
  output : Gh.Repo_id.t * string;
  repos : (Gh.Repo_id.t * File.Copy.info list * File.Data.info list) list;
  indexes : File.Index.t list;
}

let repos t = t.repos
let output t = t.output
let indexes t = t.indexes

module JSON = struct
  let extract_string = function
    | `String str -> str
    | _ -> failwith "Trying to convert something into a string."

  let output_to_json output =
    Current_github.Repo_id.(
      let { owner; name }, branch = output in
      `Assoc
        [
          ("owner", `String owner);
          ("name", `String name);
          ("branch", `String branch);
        ])

  let output_of_json = function
    | `Assoc output ->
        let owner = List.assoc "owner" output |> extract_string in
        let name = List.assoc "name" output |> extract_string in
        let branch = List.assoc "branch" output |> extract_string in
        (Current_github.Repo_id.{ owner; name }, branch)
    | _ -> failwith "Corrupted data / output: this is not supposed to happen."

  let repo_to_json repos : Yojson.Safe.t =
    let f (repo_id, files, data) : Yojson.Safe.t =
      let name =
        Current_github.Repo_id.(
          let { owner; name } = repo_id in
          Printf.sprintf "%s/%s" owner name)
      in
      let files : Yojson.Safe.t =
        `List (List.map File.Copy.info_to_yojson files)
      in
      let data : Yojson.Safe.t = `List (List.map File.Data.info_to_json data) in
      `Assoc [ (name, `Assoc [ ("files", files); ("data", data) ]) ]
    in
    `List (List.map f repos)

  let repo_of_json json =
    let f = function
      | `Assoc
          [ (name, `Assoc [ ("files", `List files); ("data", `List data) ]) ] ->
          let repo_id =
            match String.split_on_char '/' name with
            | [ owner; name ] -> Current_github.Repo_id.{ owner; name }
            | _ ->
                failwith
                  "Corrupted data - repo/f/repo_id: this is not supposed to \
                   happen."
          in
          let files =
            let f file = File.Copy.info_of_yojson file |> Result.get_ok in
            List.map f files
          in
          let data = List.map File.Data.info_of_json data in
          (repo_id, files, data)
      | _ -> failwith "Corrupted data - repo/f: this is not supposed to happen."
    in
    match json with
    | `List json -> List.map f json
    | _ -> failwith "Corrupted data / repo: this is not supposed to happen."

  let index_to_json indexes = `List (List.map File.Index.to_json indexes)

  let index_of_json = function
    | `List json -> List.map File.Index.of_json json
    | _ -> failwith "Corrupted data / index: this is not supposed to happen."

  let conf_to_json t =
    let output : Yojson.Safe.t = output_to_json t.output in
    let repos : Yojson.Safe.t = repo_to_json t.repos in
    let indexes : Yojson.Safe.t = index_to_json t.indexes in
    `Assoc [ ("output", output); ("repos", repos); ("indexes", indexes) ]

  let conf_of_json : Yojson.Safe.t -> t = function
    | `Assoc [ ("output", output); ("repos", repos); ("indexes", indexes) ] ->
        let output = output_of_json output in
        let repos = repo_of_json repos in
        let indexes = index_of_json indexes in
        { output; repos; indexes }
    | _ -> failwith "Corrupted data - conf: this is not supposed to happen."
end

let github_remote conf =
  let { Current_github.Repo_id.owner; Current_github.Repo_id.name }, branch =
    conf.output
  in
  let url = Printf.sprintf "git@github.com:%s/%s.git" owner name in
  (url, branch)

module Static = struct
  let hugo_output = "public"
  let remote_name = "deploy"
end

module Yaml = struct
  module Y = Utils.Yaml

  let file_info_of_yaml yaml =
    let title = Y.access_str ~field:"title" yaml in
    let summary = Y.access_str ~field:"summary" yaml in
    let authors = Y.access_str_array ~field:"authors" yaml in
    let src = Fpath.v (Y.access_str ~field:"src" yaml) in
    let dst = Fpath.v (Y.access_str ~field:"dst" yaml) in
    File.Copy.v ~title ~summary ~authors ~src ~dst ()

  let data_info_of_yaml yaml =
    let src = Fpath.v (Y.access_str ~field:"src" yaml) in
    let dst = Fpath.v (Y.access_str ~field:"dst" yaml) in
    File.Data.v ~src ~dst

  let repo_of_yaml yaml =
    let owner = Y.access_str ~field:"owner" yaml in
    let name = Y.access_str ~field:"name" yaml in
    let files = Y.access_array ~field:"files" file_info_of_yaml yaml in
    let data = Y.access_array ~field:"data" data_info_of_yaml yaml in
    (Gh.Repo_id.{ owner; name }, files, data)

  let index_of_yaml yaml =
    let title = Y.access_str ~field:"title" yaml in
    let description = Y.access_str ~field:"description" yaml in
    let dst = Fpath.v (Y.access_str ~field:"dst" yaml) in
    File.Index.v ~title ~description ~dst

  let output_of_yaml yaml =
    let yaml = Y.access ~field:"output" yaml in
    let output =
      let owner = Y.access_str ~field:"owner" yaml in
      let name = Y.access_str ~field:"name" yaml in
      Gh.Repo_id.{ owner; name }
    in
    let branch = Y.access_str ~field:"branch" yaml in
    (output, branch)

  let from_file path =
    let yaml = Y.parse_file path in
    {
      output = output_of_yaml yaml;
      repos = Y.access_array ~field:"repos" repo_of_yaml yaml;
      indexes = Y.access_array ~field:"indexes" index_of_yaml yaml;
    }
end

module Reloader = struct
  open Lwt.Infix

  type conf = t
  type t = No_context

  let id = "conf-loader"

  module Key = struct
    type t = { commit : Current_git.Commit.t }

    let to_json t =
      let commit = Current_git.Commit.hash t.commit in
      `Assoc [ ("commit", `String commit) ]

    let digest t = Yojson.Safe.to_string (to_json t)
    let pp f t = Fmt.pf f "%s" (Current_git.Commit.hash t.commit)
  end

  module Value = struct
    type t = conf

    let marshal t = Yojson.Safe.to_string (JSON.conf_to_json t)
    let unmarshal s = JSON.conf_of_json (Yojson.Safe.from_string s)
  end

  let build No_context job { Key.commit } =
    Current.Job.start job ~level:Current.Level.Average >>= fun () ->
    Current_git.with_checkout ~job commit @@ fun dir ->
    let path = Fpath.add_seg dir "tracker.yml" in
    let conf = Yaml.from_file path in
    let dump = Yojson.Safe.to_string (JSON.conf_to_json conf) in
    Current.Job.log job "The configuration used to build the website is:\n %s"
      dump;
    Lwt_result.return conf

  let pp f key = Fmt.pf f "@[<v2>Reload config for commit %a@]" Key.pp key
  let auto_cancel = true
end

module Cache_reloader = Current_cache.Make (Reloader)

let lint ?(test = false) file =
  try
    let conf = Yaml.from_file file in
    if test then ignore (JSON.conf_to_json conf |> JSON.conf_of_json);
    (* Ensure the functions are inverse functions that validate f (f^-1(x)) = x. *)
    Result.ok ()
  with Invalid_argument s ->
    let msg =
      Printf.sprintf "The execution stops because of an invalid argument: %s" s
    in
    Result.error (`Msg msg)

let load commit =
  Current.component "config-loader"
  |> let> commit = commit in
     Cache_reloader.get No_context { Reloader.Key.commit }
