module Cmd = struct
  let copy ?cwd ~job args =
    let args = "cp" :: args in
    Current.Process.exec ?cwd ~job ~cancellable:true ("cp", Array.of_list args)

  let copy_all ?cwd ~job src dst =
    let src = Fpath.add_seg src "." |> Fpath.to_string in
    let dst = Fpath.to_string dst in
    let args = [ "-ra"; src; dst ] in
    copy ?cwd ~job args

  let mv args =
    let open Lwt.Syntax in
    let args = "mv" :: args in
    let* status = Lwt_process.exec ("mv", Array.of_list args) in
    Unix.(
      match status with
      | WEXITED 0 -> Lwt.return_unit
      | WEXITED n ->
          let msg = Printf.sprintf "mv: exited with a non zero status (%d)" n in
          Lwt.fail_with msg
      | WSTOPPED n ->
          let msg = Printf.sprintf "mv: stopped with status (%d)" n in
          Lwt.fail_with msg
      | WSIGNALED n ->
          let msg = Printf.sprintf "mv: signaled with status (%d)" n in
          Lwt.fail_with msg)

  let move src dst =
    let src = Fpath.to_string src in
    let dst = Fpath.to_string dst in
    let args = [ src; dst ] in
    mv args
end

module Dir = struct
  open Lwt.Infix

  (* This function comes from the {!Current.Process} module *)
  let rm_f_tree root =
    let rec rmtree path =
      Lwt_unix.lstat path >>= fun info ->
      match info.Unix.st_kind with
      | Unix.S_REG | Unix.S_LNK | Unix.S_BLK | Unix.S_CHR | Unix.S_SOCK
      | Unix.S_FIFO ->
          Lwt_unix.unlink path
      | Unix.S_DIR ->
          Lwt_unix.chmod path 0o700 >>= fun () ->
          Lwt_unix.files_of_directory path
          |> Lwt_stream.iter_s (function
               | "." | ".." -> Lwt.return_unit
               | leaf -> rmtree (Filename.concat path leaf))
          >>= fun () -> Lwt_unix.rmdir path
    in
    rmtree root

  let check_dir x =
    Lwt.catch
      (fun () ->
        Lwt_unix.stat x >|= function
        | Unix.{ st_kind = S_DIR; _ } -> `Present
        | _ -> Fmt.failwith "Exists, but is not a directory: %S" x)
      (function
        | Unix.Unix_error (Unix.ENOENT, _, _) -> Lwt.return `Missing
        | exn -> Lwt.fail exn)

  let ensure path =
    let path = Fpath.to_string path in
    check_dir path >>= function
    | `Present ->
        Logs.debug (fun f -> f "Directory %s exists" path);
        Lwt.return_unit
    | `Missing ->
        Logs.info (fun f -> f "Creating %s directory" path);
        Lwt_unix.mkdir path 0o777

  let delete path =
    let path = Fpath.to_string path in
    check_dir path >>= function
    | `Present ->
        Logs.info (fun f -> f "Delete directory %s" path);
        rm_f_tree path
    | `Missing ->
        Logs.debug (fun f -> f "Skip deletion for %s directory" path);
        Lwt.return_unit
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
    try access ~field yaml |> from_array |> List.map f
    with Invalid_argument _ -> []

  let access_str_array ~field yaml = access_array ~field from_string yaml
end
