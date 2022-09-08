module Gh = Current_github

let setup_log style_renderer default_level =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Prometheus_unix.Logging.init ?default_level ()

let program_name = "pipeline"

let has_role user = function
  | `Viewer | `Monitor -> true
  | `Builder | `Admin -> (
      match Option.map Current_web.User.id user with
      | Some ("github:maiste" | "github:tmcgilchrist" | "github:MisterDA ") ->
          true
      | _ -> false)

let webhook_route ~engine ~has_role ~webhook_secret =
  Routes.(
    (s "webhooks" / s "github" /? nil)
    @--> Gh.webhook ~engine ~has_role ~webhook_secret)

let login_route github_auth =
  Routes.((s "login" /? nil) @--> Gh.Auth.login github_auth)

let main () config mode branch app github_auth =
  let authn = Option.map Gh.Auth.make_login_uri github_auth in
  let has_role =
    if github_auth = None then Current_web.Site.allow_all else has_role
  in
  let secure_cookies = github_auth <> None in
  let webhook_secret = String.trim (Gh.App.webhook_secret app) in
  let engine = Current.Engine.create ~config (Pipeline.v ~branch ~app) in
  let routes =
    webhook_route ~engine ~has_role ~webhook_secret
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

let setup_log =
  let docs = Manpage.s_common_options in
  Term.(const setup_log $ Fmt_cli.style_renderer () $ Logs_cli.level ~docs ())

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
        $ branch
        $ Gh.App.cmdliner
        $ Gh.Auth.cmdliner))

let () = Cmd.(exit @@ eval cmd)
