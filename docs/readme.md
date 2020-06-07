# Start mkdocs
```bash
# pull the image
docker pull samlinux/mkdocs_readthedocs

# start the preview server
docker-compose up

# build the site
docker exec -it mkdocs mkdocs build
```