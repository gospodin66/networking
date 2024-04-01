#!/bin/sh

cat << EndOfMessage

::::::::::::::::::::::::::::::::::
Configuring user tunnel:
  - generate GPG key 
  - generate SSH keypair 
  - upload SSH key to jump server 
  - connect to jump server
  - generate SSH keypair
  - upload SSH key to dest server
::::::::::::::::::::::::::::::::::

EndOfMessage
docker exec -it -u tunnel -w /home/tunnel user sh -c "./gen-key-encrypt-file.sh .pconfig && ./handle_keys.exp .config"

cat << EndOfMessage

::::::::::::::::::::::::::::::::::::::::::::::::::
Opening tunnel dest -> (router) -> net1-probe
                        -> (router) -> net2-probe
::::::::::::::::::::::::::::::::::::::::::::::::::

EndOfMessage
docker exec -u dest -w /home/dest dest sh -c "./tunnel-router-net1_net2.exp $(docker exec net-router hostname) &"

if [ $? -ne 0 ]; then
  echo -e "ERROR: Tunnel not open"
  exit 1
fi

cat << EndOfMessage

::::::::::::::::::::::::::::::::::::::::::::::
Opening tunnel user -> (jump) -> dest
::::::::::::::::::::::::::::::::::::::::::::::

EndOfMessage
docker exec -u tunnel -w /home/tunnel user sh -c "./tunnel.exp .config pubkey &"

echo "done!"

cat << EndOfMessage

:::::::::::::::::::::::::::::::::::::::::::::::::::::
you are now able to connect from user to outside: 
-- open tunnel to net1-probe: 
$ docker exec -it user ssh -p 21122 tunneller@172.17.0.4
-- open tunnel to net2-probe: 
$ docker exec -it user ssh -p 21222 tunneller@172.17.0.4
:::::::::::::::::::::::::::::::::::::::::::::::::::::

EndOfMessage

exit 0