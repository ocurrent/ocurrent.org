module Gh = Current_github

let setup_log style_renderer default_level =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Prometheus_unix.Logging.init ?default_level ()

let read_channel_uri path =
  let read_first_line path =
    let ch = open_in path in
    Fun.protect (fun () -> input_line ch) ~finally:(fun () -> close_in ch)
  in
  try
    let uri = read_first_line path in
    Current_slack.channel (Uri.of_string (String.trim uri))
  with ex ->
    Fmt.failwith "Failed to read slack URI from %S: %a" path Fmt.exn ex

let program_name = "pipeline"

let has_role user = function
  | `Viewer | `Monitor -> true
  | `Builder | `Admin -> (
      match Option.map Current_web.User.id user with
      | Some ("github:maiste" | "github:tmcgilchrist" | "github:MisterDA ") ->
          true
      | _ -> false)

let webhook_route ~engine ~webhook_secret =
  let get_job_ids ~owner:_ ~name:_ ~hash:_ = [] in
  Routes.(
    (s "webhooks" / s "github" /? nil)
    @--> Gh.webhook ~engine ~get_job_ids ~webhook_secret)

let login_route github_auth =
  Routes.((s "login" /? nil) @--> Gh.Auth.login github_auth)

let lint () file test =
  let path = Fpath.v file in
  Result.map
    (fun () ->
      Fmt.(pr "[%a]: %s is correct.\n%!" (styled `Green string) "OK" file))
    (Conf.lint ~test path)

let main () channel config mode branch app github_auth =
  let channel = Option.map read_channel_uri channel in
  let authn = Option.map Gh.Auth.make_login_uri github_auth in
  let has_role =
    if github_auth = None then Current_web.Site.allow_all else has_role
  in
  let secure_cookies = github_auth <> None in
  let webhook_secret = String.trim (Gh.App.webhook_secret app) in
  let engine =
    Current.Engine.create ~config (Pipeline.v ?channel ~branch ~app)
  in
  let routes =
    webhook_route ~engine ~webhook_secret
    :: login_route github_auth
    :: Current_web.routes engine
  in
  let site =
    Current_web.Site.(
      v ?authn ~has_role ~secure_cookies ~name:program_name routes)
  in
  Lwt_main.run
    (Lwt.choose [ Current.Engine.thread engine; Current_web.run ~mode site ])

open Cmdliner

let slack_t =
  Arg.value
  @@ Arg.opt Arg.(some file) None
  @@ Arg.info
       ~doc:"A file containing the URI of the endpoint for status updates"
       ~docv:"URI-FILE" [ "slack" ]

let setup_log_t =
  let docs = Manpage.s_common_options in
  Term.(const setup_log $ Fmt_cli.style_renderer () $ Logs_cli.level ~docs ())

let branch_t =
  let doc = "Selected GitHub branch where to fetch the tracker file." in
  Arg.(value @@ opt string "main" @@ info ~doc ~docv:"BRANCH" [ "branch"; "b" ])

let test_t =
  let doc = "Specify if the code is executed in a test environment or not." in
  Arg.(value @@ flag @@ info ~doc [ "test"; "t" ])

let conf_t =
  Arg.(
    required
    @@ opt (some file) None
    @@ info ~doc:"The YAML tracker file" ~docv:"FILE" [ "file"; "f" ])

let lint_cmd =
  let name = "lint" in
  let doc = "Linter to check the tracker file is correct" in
  let info = Cmd.info ~doc name in
  Cmd.v info Term.(term_result (const lint $ setup_log_t $ conf_t $ test_t))

let run_cmd =
  let name = "run" in
  let doc = "Run the OCurrent pipeline" in
  let info = Cmd.info ~doc name in
  Cmd.v info
    Term.(
      term_result
        (const main
        $ setup_log_t
        $ slack_t
        $ Current.Config.cmdliner
        $ Current_web.cmdliner
        $ branch_t
        $ Gh.App.cmdliner
        $ Gh.Auth.cmdliner))

let cmd =
  let doc = "an OCurrent pipeline" in
  let info = Cmd.info program_name ~doc in
  Cmd.group info [ run_cmd; lint_cmd ]

let () = Cmd.(exit @@ eval cmd)
