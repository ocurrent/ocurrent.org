let git ?cwd ~job args =
  let cmd = "git" :: args in
  Current.Process.exec ?cwd ~job ~cancellable:true ("git", Array.of_list cmd)

let init ?cwd ~job () =
  let args = [ "init" ] in
  git ?cwd ~job args

let fetch ?cwd ~job ?depth remote branch =
  let args = [ "fetch"; remote; branch ] in
  let args =
    match depth with
    | None -> args
    | Some depth ->
        let depth = Printf.sprintf "--depth=%d" depth in
        args @ [ depth ]
  in
  git ?cwd ~job args

let switch ?cwd ~job branch =
  let args = [ "switch"; branch ] in
  git ?cwd ~job args

let remote ?cwd ~job = function
  | `Add (name, url) ->
      let args = [ "remote"; "add"; name; url ] in
      git ?cwd ~job args

let add_all ?cwd ~job () =
  let args = [ "add"; "." ] in
  git ?cwd ~job args

let rm_all ?cwd ~job () =
  let args = [ "rm"; "-rf"; "*" ] in
  git ?cwd ~job args

let commit ?cwd ~job ?(allow_empty = false) msg =
  let allow_empty = if allow_empty then [ "--allow-empty" ] else [] in
  let args = "commit" :: "-m" :: msg :: allow_empty in
  git ?cwd ~job args

let push ?cwd ~job ?(force = false) remote branch =
  let force = if force then [ "--force" ] else [] in
  let args = "push" :: remote :: branch :: force in
  git ?cwd ~job args
