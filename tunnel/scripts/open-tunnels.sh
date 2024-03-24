#!/bin/sh

cat << EndOfMessage

::::::::::::::::::::::::::::::::::
Configuring ssh-user tunnel:
  - generate GPG key 
  - generate SSH keypair 
  - upload SSH key to jump server 
  - connect to jump server
  - generate SSH keypair
  - upload SSH key to dest server
::::::::::::::::::::::::::::::::::

EndOfMessage
docker exec -it -u tunnel -w /home/tunnel ssh-user sh -c "./gen-key-encrypt-file.sh .pconfig && ./handle_keys.exp .config"

cat << EndOfMessage

::::::::::::::::::::::::::::::::::::::::::::::::::
Opening tunnel ssh-dest -> (router) -> net1-probe
                        -> (router) -> net2-probe
::::::::::::::::::::::::::::::::::::::::::::::::::

EndOfMessage
docker exec -u dest -w /home/dest ssh-dest sh -c "./tunnel-router-net1_net2.exp $(docker exec net-router hostname) &"

cat << EndOfMessage

::::::::::::::::::::::::::::::::::::::::::::::
Opening tunnel ssh-user -> (jump) -> ssh-dest
::::::::::::::::::::::::::::::::::::::::::::::

EndOfMessage
docker exec -u tunnel -w /home/tunnel ssh-user sh -c "./ssh_tunnel.exp .config pubkey &"

echo "done!"

cat << EndOfMessage

:::::::::::::::::::::::::::::::::::::::::::::::::::::
you are now able to connect from ssh-user to outside: 
-- open tunnel to net1-probe: 
$ docker exec -it ssh-user ssh -p 21122 tunneller@172.17.0.4
-- open tunnel to net2-probe: 
$ docker exec -it ssh-user ssh -p 21222 tunneller@172.17.0.4
:::::::::::::::::::::::::::::::::::::::::::::::::::::

EndOfMessage

exit 0