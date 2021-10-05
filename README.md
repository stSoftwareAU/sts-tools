# 🟩 dga-tools

Shared scripts to deploy infrastructure. 

```shell
~/src/dga-tools/run.sh -w $(pwd) -m apply
```

REPL mode 
```shell
~/src/dga-tools/run.sh --workspace $(pwd) --mode repl
```
```
REPL dga-services:Develop

1) BUILD:   Build the docker image
2) APPLY:   Apply the IaC
3) PUSH:    Push the docker image
4) PULL:    Pull the docker image
5) RELEASE: Release the docker image
6) IMPORT:  Import a manually created element
9) SHELL:   Bash shell

0) EXIT
Choice> 
```
