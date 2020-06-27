#!/bin/bash

# if your work is done, build the site
docker exec -it mkdocs mkdocs build

# add and commit
git add . && git commit -am "modify text"

# we push all to the github server
git push

# if we are ready to pull the new version on docker01
ssh root@pandora.samlinux.com 'bash /root/bin/updateHsc.sh'
