open Current.Syntax
module Gh = Current_github
module Git = Current_git

module Metrics = struct
  open Prometheus

  let namespace = "ocurrent"
  let subsystem = "watcher"

  let build ~help ~repo metric =
    let owner =
      String.map (function '.' | '-' -> '_' | c -> c) repo.Gh.Repo_id.owner
    in
    let name =
      String.map (function '.' | '-' -> '_' | c -> c) repo.Gh.Repo_id.name
    in
    let field = Printf.sprintf "%s_%s_%s" owner name metric in
    Gauge.v ~help ~namespace ~subsystem field

  let repo_total repo =
    let help = "Total number of repositories built." in
    build ~help ~repo "repo_total"

  let inc_one_repo reporter = Prometheus.Gauge.inc_one reporter

  let asset_total repo =
    let help = "Total number of assets built." in
    build ~help ~repo "asset_total"

  let report_asset ~reporter l =
    let size = List.length l |> float_of_int in
    Prometheus.Gauge.inc reporter size
end

type selection = {
  repo : string;
  commit : Git.Commit.t Current.t;
  files : File.Copy.info list;
  data : File.Data.info list;
}

let fetch_commit ?branch ~github ~repo () =
  let head =
    match branch with
    | None -> Gh.Api.head_commit github repo
    | Some branch ->
        let ref = String.concat "/" [ "refs"; "heads"; branch ] in
        Gh.Api.head_of github repo (`Ref ref)
  in
  let commit_id = Current.map Gh.Api.Commit.id head in
  (repo.name, Git.fetch commit_id)

let fetch_selections ~asset_reporter ~repo_reporter ~github ~repos =
  let f (repo, files, data) =
    let repo, commit = fetch_commit ~github ~repo () in
    Metrics.report_asset ~reporter:asset_reporter files;
    Metrics.report_asset ~reporter:asset_reporter data;
    Metrics.inc_one_repo repo_reporter;
    { repo; commit; files; data }
  in
  List.map f repos

let fetch_file_content selections =
  let f { repo; commit; files; _ } = Content.fetch ~repo ~commit files in
  List.map f selections

let memorize selections =
  let f { repo; commit; data; _ } = Content.store ~repo ~commit data in
  List.map f selections

let v ~branch ~app () =
  Gh.App.installations app
  |> Current.list_iter ~collapse_key:"org" (module Gh.Installation)
     @@ fun installation ->
     let github = Current.map Gh.Installation.api installation in
     Gh.Installation.repositories installation
     |> Current.list_iter ~collapse_key:"monitor" (module Gh.Api.Repo)
        @@ fun repo ->
        let* repo = Current.map Gh.Api.Repo.id repo and* github = github in
        let repo_reporter = Metrics.repo_total repo in
        let asset_reporter = Metrics.asset_total repo in
        Prometheus.Gauge.set repo_reporter 0.0;
        Prometheus.Gauge.set asset_reporter 0.0;
        let commit = snd (fetch_commit ~branch ~github ~repo ()) in
        Current.component "Get selection files"
        |> let** conf = Conf.load commit in
           let repos = Conf.repos conf in
           let selections =
             fetch_selections ~asset_reporter ~repo_reporter ~github ~repos
           in
           let files =
             fetch_file_content selections
             |> Current.list_seq
             |> Current.map List.flatten
           in
           let indexes = Conf.indexes conf in
           let data =
             memorize selections |> Current.list_seq |> Current.map List.flatten
           in
           Hugo.build ~commit ~conf files indexes data
