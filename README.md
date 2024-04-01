---
### Virtual networks
Base lab stack for further arbitrary work. \
Consists of:
- 2 private networks (`net1` & `net2`) -> internal networks used as forwarding endpoints
    - Each of net1 and net2 consists of:
        - n dummy containers (`networking_n1|n2_xy`)
        - 1 probe container  (`net1|net2-probe`) 
- 1 router network (`router-net`) -> used to forward all traffic. 
    - Router network initially consists of:
        - 1 router container (`net-router`)
        - Container `dest` connects to it to forward traffic to private networks.

Nodes can initially communicate from `net1` with nodes from `net2` and vice versa. \
Addition to base network stack is `./tunnel/` module which is docker's default `bridge` network. \
Consists of:
- 2 ssh servers (`jump` & `dest`) -> jump server tunnels to dest server
- 1 client      (`user`)              -> **starting point**. 

### Pre-setup
Rename all `.example` files to original names and populate the values in `.(p|t)config` files

### Additional Info
Using ssh tunnels, user can connect nodes in both `net1` & `net2` networks via 2 tunnels (see topology). \
Note: In order for nodes to become visible in another network, router needs to ping them to discover. This action is needed since the IP addresses are updated manually from DHCP-assigned addresses to gateways (`10.110.0.1` & `10.120.0.1`) on router. (this action is done automatically during setup)

#### Setup
Running base network stack:
```bash

###
### pre-install docker
###

$ git clone <repository>
$ cd <repository>/setup
$ ./setup.sh
```

Running ssh tunnel stack:
```bash
# ssh tunnel setup | key upload | tunnel open | test:
# user is prompted to enter passphrase twice (1 for generation, 1 for usage during key upload to jump server)

$ cd <repository>/tunnel
$ ./setup.sh

# connect from 172.17.0.2 to 10.110.0.110 (fwd-port: 21122) 
#                         to 10.120.0.120 (fwd-port: 21222)  
# through (172.17.0.4(10.140.0.2) <-> 10.140.0.140(10.110.0.1|10.120.0.1) <-> 10.110.0.110|10.120.0.120):
$ docker exec -it -u tunnel -w /home/tunnel user ssh -p 21122 tunneller@172.17.0.4
$ docker exec -it -u tunnel -w /home/tunnel user ssh -p 21222 tunneller@172.17.0.4
```

Setup pipeline:
```bash
# setup self-hosted runner
# -- pre-step: adapt params in build-runner.sh
$ cd networking/setup
$ ./ build-runner.sh

# run self-hosted runner
$ cd actions-runner/
$ ./runsvc.sh
```

##### Topology

Base network topology consists of `net1` `net2` `net-router` networks. \
When running `*` tunnel containers, `default docker network` is added into topology.


```bash 
                      |-------------|                               |-------------|
                ------|10.110.0.0/16|                               |10.120.0.0/16|------
                |     |-------------|                               |-------------|     |
                |     |     net1    |                               |     net2    |     |
                |     |-------------|                               |-------------|     |
                |                                                                       |
                |                                                                       |
                |   default traffic                                   default traffic   |
                -----------------------                             ---------------------
                -----------------------                             ---------------------
                       tunnel         |                             |      tunnel
                                      |                             |
                                      |                             |
        |-------------|               |                             |
        | isolated net|               |       |-------------|       |
        |-------------|               --------|10.120.0.1   |--------
                                      --------|10.110.0.1   |--------
                                              |10.140.0.140 |<--------------
                                              |-------------|              |
   ------------------------------------------>|GW:10.140.0.1|              | t
   |                                          |-------------|              | u
   |                                          | net-router  |              | n
   |                                          |-------------|              | n
   |                                                                       | e
   |                                                                       | l
   |                          ---------------------------------------------|-------------
   |d                         |                                            |            |
   |e                         |                   |-------------|          |            |
   |f          ---------------------------------->|GW:172.17.0.1|          |            |
   |a          |d             |                   |-------------|          |            |
   |u          |e             |                default docker network      |            |
   |l          |f             |                                            |            |
   |t          |a             |                                            V            |
   |           |u             |                                      |-------------|    |
   |           |l             |    |-------------|  |-------------|  |10.140.0.2   |    |
   |t          |t             |    |172.17.0.2   |  |172.17.0.3   |  |172.17.0.4   |    |
   |r          |              |    |-------------|  |-------------|  |-------------|    |
   |a          |              |    |GW:172.17.0.1|  |GW:172.17.0.1|  |GW:172.17.0.1|    |
   |f          |t             |    |-------------|  |-------------|  |-------------|    |
   |f          |r             |    |      user   |  |       jump  |  |       dest  |    |
   |i          |a             |    |-------------|  |---+++++++---|  |-------------|    |
   |c          |f             |            |            |     |            |            |
   |           |f             |            |-------------     -------------|            |
   |           |i             |                         tunnel                          |
   |           |c             -----------------------------------------------------------
   |           | 
   |           -------
   --------------    |
                |    |
                |    |
                V    V
               Internet
```

