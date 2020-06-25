#!/bin/bash

# we push all to the github server
git push


# if we are ready to pull the new version on docker01
ssh root@pandora.samlinux.com 'bash /root/bin/updateHsc.sh'
