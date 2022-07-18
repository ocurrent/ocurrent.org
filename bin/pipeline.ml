module Gh = Current_github
module Git = Current_git

type selection = {
  repo : string;
  commit : Git.Commit.t Current.t;
  files : File.Copy.info list;
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

let fetch_selections ~github ~repos =
  let f selections (repo, files) =
    let repo, commit = fetch_commit ~github ~repo () in
    { repo; commit; files } :: selections
  in
  List.fold_left f [] repos

let fetch_file_content selections =
  let f { repo; commit; files } = Content.fetch ~repo ~commit files in
  List.map f selections

let v ~config ~github () =
  let repos = Conf.repos config in
  let repo, branch = Conf.base config in
  let commit = snd (fetch_commit ~github ~repo ~branch ()) in
  let selections = fetch_selections ~github ~repos in
  let files =
    let files = fetch_file_content selections in
    Current.list_seq files |> Current.map List.flatten
  in
  let indexes = Conf.indexes config in
  Hugo.build ~commit files indexes
