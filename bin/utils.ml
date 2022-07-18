open Lwt_result.Syntax

module Cmd = struct
  let copy ?cwd ~job args =
    let args = "cp" :: args in
    Current.Process.exec ?cwd ~job ~cancellable:true ("cp", Array.of_list args)

  let copy_all ?cwd ~job src dst =
    let* srcs =
      match Bos.OS.Dir.contents src with
      | Ok l ->
          let l = List.map Fpath.to_string l in
          Lwt_result.return l
      | Error e -> Lwt_result.fail e
    in
    let dst = [ Fpath.to_string dst ] in
    let args = "-a" :: (srcs @ dst) in
    copy ?cwd ~job args
end

module Yaml = struct
  let read_file path =
    let ch = open_in_bin path in
    Fun.protect
      (fun () ->
        let len = in_channel_length ch in
        really_input_string ch len)
      ~finally:(fun () -> close_in ch)

  let parse_file path =
    let path = Fpath.to_string path in
    let content = read_file path in
    Yaml.of_string_exn content

  let from_string = function
    | `String str -> str
    | _ ->
        invalid_arg
          "Converter is trying to parse a section that is not a string."

  let from_list = function
    | `O o -> o
    | _ ->
        invalid_arg
          "Converter is trying to parse a section that is not an object."

  let from_array = function
    | `A a -> a
    | _ ->
        invalid_arg "Converter is trying to parse a section that is not array."

  let access ~field yaml =
    let obj = from_list yaml in
    match List.assoc field obj with
    | value -> value
    | exception Not_found ->
        let msg =
          Format.(
            sprintf "Can't find the field (%s) in the object\n%s" field
              (Yaml.to_string_exn yaml))
        in
        invalid_arg msg

  let access_str ~field yaml = access ~field yaml |> from_string

  let access_array ~field f yaml =
    access ~field yaml |> from_array |> List.map f

  let access_str_array ~field yaml = access_array ~field from_string yaml
end
