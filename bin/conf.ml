module Gh = Current_github

type t = {
  base : Gh.Repo_id.t * string;
  repos : (Gh.Repo_id.t * File.Copy.info list) list;
  indexes : File.Index.t list;
}

let repos t = t.repos
let base t = t.base
let indexes t = t.indexes

module Y = Utils.Yaml

let info_of_yaml yaml =
  let title = Y.access_str ~field:"title" yaml in
  let summary = Y.access_str ~field:"summary" yaml in
  let authors = Y.access_str_array ~field:"authors" yaml in
  let src = Fpath.v (Y.access_str ~field:"src" yaml) in
  let dst = Fpath.v (Y.access_str ~field:"dst" yaml) in
  File.Copy.v ~title ~summary ~authors ~src ~dst ()

let repo_of_yaml yaml =
  let owner = Y.access_str ~field:"owner" yaml in
  let name = Y.access_str ~field:"name" yaml in
  let files = Y.access_array ~field:"files" info_of_yaml yaml in
  (Gh.Repo_id.{ owner; name }, files)

let index_of_yaml yaml =
  let title = Y.access_str ~field:"title" yaml in
  let summary = Y.access_str ~field:"summary" yaml in
  let dst = Fpath.v (Y.access_str ~field:"dst" yaml) in
  File.Index.v ~title ~summary ~dst ()

let base_of_yaml yaml =
  let yaml = Y.access ~field:"base" yaml in
  let base =
    let owner = Y.access_str ~field:"owner" yaml in
    let name = Y.access_str ~field:"name" yaml in
    Gh.Repo_id.{ owner; name }
  in
  let branch = Y.access_str ~field:"branch" yaml in
  (base, branch)

let from_file path =
  let yaml = Y.parse_file path in
  {
    base = base_of_yaml yaml;
    repos = Y.access_array ~field:"repos" repo_of_yaml yaml;
    indexes = Y.access_array ~field:"indexes" index_of_yaml yaml;
  }

module Static = struct
  let owner = "ocurrent-test"
  let name = "occurent-test.github.io"
  let hugo_output = "public"
  let remote_name = "deploy"
  let output_branch = "main"

  let remote =
    let url = Format.sprintf "git@github.com:%s/%s.git" owner name in
    (remote_name, url)
end
