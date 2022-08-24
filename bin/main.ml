module Gh = Current_github

let setup_log default_level = Prometheus_unix.Logging.init ?default_level ()
let program_name = "pipeline"

let read_file path =
  let ch = open_in_bin path in
  Fun.protect
    (fun () ->
      let len = in_channel_length ch in
      really_input_string ch len)
    ~finally:(fun () -> close_in ch)

let webhook_route ~engine ~has_role ~webhook_secret =
  Routes.(
    (s "webhooks" / s "github" /? nil)
    @--> Current_github.webhook ~engine ~has_role ~webhook_secret)

let main () config mode repo branch token webhook_secret =
  let token = String.trim (read_file token) in
  let webhook_secret = String.trim (read_file webhook_secret) in
  let github = Gh.Api.of_oauth ~token ~webhook_secret in
  let engine =
    Current.Engine.create ~config (Pipeline.v ~repo ~branch ~github)
  in
  let has_role = Current_web.Site.allow_all in
  let routes =
    webhook_route ~engine ~has_role ~webhook_secret :: Current_web.routes engine
  in
  let site = Current_web.Site.(v ~has_role ~name:program_name routes) in
  Lwt_main.run
    (Lwt.choose [ Current.Engine.thread engine; Current_web.run ~mode site ])

open Cmdliner

let setup_log =
  let docs = Manpage.s_common_options in
  Term.(const setup_log $ Logs_cli.level ~docs ())

let token =
  Arg.required
  @@ Arg.opt Arg.(some file) None
  @@ Arg.info ~doc:"Token path" ~docv:"PATH" [ "github-token-file"; "t" ]

let webhook_secret =
  Arg.required
  @@ Arg.opt Arg.(some file) None
  @@ Arg.info ~doc:"Webhook secret path" ~docv:"PATH"
       [ "github-webhook-secret-file"; "w" ]

let repo =
  Arg.required
  @@ Arg.opt Arg.(some Current_github.Repo_id.cmdliner) None
  @@ Arg.info ~doc:"The base repository to build the config from."
       ~docv:"REPO/OWNER" [ "repo"; "r" ]

let branch =
  Arg.required
  @@ Arg.opt Arg.(some string) None
  @@ Arg.info ~doc:"Git branch of repo" ~docv:"branch" [ "branch"; "b" ]

let cmd =
  let doc = "an OCurrent pipeline" in
  let info = Cmd.info program_name ~doc in
  Cmd.v info
    Term.(
      term_result
        (const main
        $ setup_log
        $ Current.Config.cmdliner
        $ Current_web.cmdliner
        $ repo
        $ branch
        $ token
        $ webhook_secret))

let () = Cmd.(exit @@ eval cmd)
