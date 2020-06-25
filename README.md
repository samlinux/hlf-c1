# hlf-c1 - Hyperleder Fabric course material

## Start ReadTheDocs preview
```bash
# pull the image for the first time
docker pull samlinux/mkdocs_readthedocs

# start the preview server (if the image hasn't pulled before, it will be pulled by the first run)
docker-compose up

# open your browser 
http://localhost:8000

```

## Build the docs
```bash 
# if your work is done, build the site
docker exec -it mkdocs mkdocs build

```

## Commit the docs to the local repo
```bash 
# add, commit and push your work
git add .
git commit -m "text" 
```

## Push the docs to github/samlinux and publish it on hsc.samlinux.at
```bash
./build.sh
```

[Start reading](./docs/index.md)
