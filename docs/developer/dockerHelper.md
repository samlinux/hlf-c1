# Docker snippets

Delete stopped containers
```bash
docker rm -v $(docker ps -a -q -f status=exited)
```

Delete all docker volumnes
```bash 
docker volume prune
```