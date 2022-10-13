# Under the hood

This text explains how `OCurrent.org` pipeline is written under the hood.

### Current\_github

Let's focus on a standard structure in `ocurrent`: the way to get the HEAD of a branch on GitHub and fetch the commit with Git. In the related code, we find the HEAD, then ask GitHub to give us information about the HEAD commit on the default branch and finally get the content with `git` (it returns the related commit):

```ocaml
let fetch_commit ~github ~repo () =
  let head = Current_github.API.head_commit GitHub repo in
  let commit_id =
    Current.map Current_github.Api.Commit.id head
  in
  let commit =
    Current_git.fetch commit_id
  in
  commit
  
let main =
  let github = (* GitHub App code *) in
  let commit = fetch_commit ~github ~repo () in
  (* Use the commit code *)
```

The documentation of `current_github` and `current_git` is available [online](https://www.ocurrent.org/ocurrent/index.html).

### Fetching the files

As we know how to extract data from GitHub, applying the process to various repositories will be easy. It can be noticed that the `commit` element is of type `Commit.t OCurrent.t`. To work with `OCurrent.t`, we need to "unwrap" the object with specific functions like `map` and `bind`. This post does not present how to load the content from a `Yaml`. We assume that we get a `selection list Current.t`, where `selection` is defined as:

```ocaml
type selection = {
  repo : string;
  commit : Current_git.Commit.t Current.t;
  files : 'a list;
}
```

It contains the source repository, the commit associated with the specified branch, and the list of files to monitor from this repository.

To `git clone` the content, we must apply the `fetch_commit` function.

### Copy the content

In this subsection, we will see how we can define a custom component and how to make it interact with the rest of our code.

The component is in charge of fetching the content of the files from the source directory and storing it in memory. To trigger the action only when the content changes, we will define a `Current_cache` element. Thanks to `ocurrent`, the content is cached and only rebuilt on change or request.

It manipulates some `File.info` (source, destination, ...) and produces a `File.t` when the content is read. `File.t` is simply a:

```ocaml
type File.t = {
    metadata: File.info;
    content: string list;
}
```

Our file is represented as a `string list`, as we need to be able to add more information. We know the size of the files is limited, so it is not an issue for us.
The component is defined as a `Current_cache.BUILDER` with whom the signature looks like this:

```ocaml
module type BUILDER = sig

type context

module Key : sig
  type t
  val digest: 
end

module Value : sig
    type t
    val marshall : t -> string
    val unmarshall : string -> t
end

val build :
    context -> 
    Current.Job.t -> 
    Key.t ->
    Value.t Current.or_error Lwt.t
end
```

As the `Value` and the `Key` modules only use functions to manipulate `JSON`, we can focus on the `build` function definition:

```ocaml  
  let build files job { Key.commit; Key.repo; _ } =
    Current.Job.start job ~level:Current.Level.Average >>= fun () ->
    Current_git.with_checkout ~job commit @@ fun dir ->
    extract ~job ~dir repo files
    >>= Lwt_result.return
```

It creates a temporary directory with the content fetched from `git`. Then, it extracts the data as a `File.t` and returns the result. The interesting detail here is `Current_git.with_checkout fn`. It is used to copy our code somewhere in the system temporarily. `Current.Job.start` is just some boilerplate code to start a job asynchronously.

Consequently, we can give the builder a functor to construct our cache system. Moreover, we create a function associated with it thanks to the `Content` module newly created:
```ocaml
module Content = Current_cache.Make (Content)

let weekly = Current_cache.Schedule.v ~valid_for:(Duration.of_day 7) ()

let fetch ~repo ~ commit files =
  Current.component "fetch-doc" |>
  let> commit = commit in
  Content.get ~schedule:weekly files
    {content.Key.repo; Content.Key.commit }
```

We specify the date when the cache is invalidated to trigger the rebuild at least every week.

### Build & deploy

In this last subsection, we discuss how to write all the files stored in the cache to the right place in the filesystem. We use `hugo` to build the website and `git` with `ssh` to deploy it. As we expect the information to be cached, we build a `Current_cache` module again, where the `build` function is:

```ocaml
let build { files; indexes; conf } job { Key.commit; _ } =
    Current.Job.start job ~level:Current.Level.Average >>= fun () ->
    Current_git.with_checkout ~job commit @@ fun dir ->
    write_all job dir files indexes >>= fun () ->
    Lwt_result.bind (hugo ~cwd:dir job) (fun () ->
        let f cwd =
          let commit = Current_git.Commit.hash commit in
          deploy_over_git ~cwd ~job ~conf dir commit
        in
        Current.Process.with_tmpdir f)
```

In this context, the pipeline creates an `indexes` file as `_index.md`. It's used by `hugo` to build the directory structure. This function uses the same `Current_git.checkout` process to create a temporary directory containing the website's skeleton. All the work is done in `deploy_over_git` function, but this is not relevant to go further in detail. The component writes all the `File.t.content` to the destination specified in their metadata. Once we have successfully written them, we generate the website with `hugo --minify --output-dir=public/`. Last but not least, we copy the content of the `public` repository to a fresh temporary one so we can add the files with a `git init` and push our work to GitHub. Finally, on the target repository, GitHub Pages will deploy the website. 
