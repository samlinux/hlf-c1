# hlf-c1
Hyperleder fabric course material c1

## Start ReadTheDocs preview
```bash
# pull the image for the first time
docker pull samlinux/mkdocs_readthedocs

# start the preview server (if the image hasn't pulled before, it will be pulled by the first run)
docker-compose up

# open your browser 
http://localhost:8000


# if your work is done, build the site
docker exec -it mkdocs mkdocs build

# add, commit and push your work
git add .
git commit -m "text" 
git push

# on pandora switch to docker/hsc
# checkout the new version for public access
# for https://hsc.samlinux.at

git pull

```

[Start reading](./docs/index.md)
