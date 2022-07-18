# OCurrent.org

[OCurrent.org](https://github.com/ocurrent) is the town hall for all `OCurrent` related stuffs.

:warning: This is currently on heavy development and as a result not stable at all!

## Development

### Dependencies

To be able to develop with OCurrent, you need to have the following tools installed on your system:
 - `hugo` (>= `0.100`)

To install `hugo`, you can follow these instructions on the [gohugo.io website](https://gohugo.io/getting-started/installing/).


### OCaml installation

```
opam install . --deps-only
```

### Run a development server

To run a development server, you can run this command and go to [localhost:1313](http://localhost:1313)
to see the result:
 ```
 hugo server -v
 ```
 
 To build the page as a static website, you can execute this command the website will be built into `./public`:
```
hugo --minify -d "./public"
```


