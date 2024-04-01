---
### Tunnel scripts
Tunnel scripts are used to automatically authenticate and open tunnel from user's endpoint to destination server via jump server. 

### Pre-setup
Rename all `.example` files to original names and populate the values in `.(p|t)config` files

### Info
Scripts use a `.config` file which can be updated to specific scenario. 
Authentication can be accomplished via public keys or directly via password. 

User must pre-generate temporary passwords file which is used to authenticate to SSH servers (either once or on every run). \
Temporary password file consists of two passwords (jump & destination server) split by newline `"\n"`.
```bash
echo -e "<jump_server_password>\n<destination_server_password>" > /home/tunnel/temp_p && chmod 0400 /home/tunnel/temp_p
```

Plaintext file is encrypted with GPG key and original is deleted. \
Scripts use **only encrypted password file**. \
All commands should be executed as **non-root** user. \
Permissions on temporary password file: `chmod 0400 /home/tunnel/temp_p`

Using public keys (password file **is decrypted only once** upon SSH key generation & upload):
```bash
./gen-key-encrypt-file.sh .pconfig
./handle_keys .config
./tunnel .config pubkey
```

Using passwords (password file **is decrypted every time** upon connecting to jump/dest servers):
```bash
./gen-key-encrypt-file.sh .pconfig
./tunnel .config password
```

#### Scripts
- `gen-key-encrypt-file.sh` - generate GPG key & encrypt file from .pconfig -- `./gen-key-encrypt-file.sh .pconfig`
- `handle_keys` - handles keypair generation & uploads public keys to remote servers -- `./handle_keys .config`
- `tunnel.exp` - (uses pubkey|password auth) opens SSH tunnel via jump server -- `./tunnel.exp .config <pubkey|password>`
- `tunnel.sh` - base tunnel script -- `./tunnel.sh .tconfig`


#### Connect via tunnel
Following command connects `user` to `dest` via `jump`:
```bash
$ docker exec -it -u tunnel -w /home/tunnel user ssh -p 1089 dest@localhost
```

#### SCP
Following command transfers files via tunnels:
```bash
scp dest@172.17.0.4:/home/dest/tunneltestfile tunneltestfile.txt
```

#### Run within network
Tunnel scripts can be used to connect from `dest` host to nodes in `net1` & `net2` via `net-router` container. \
User is prompted to enter passphrase twice (1 for generation, 1 for usage during key upload to jump server)

```bash

$ cd <repository>/tunnel
$ ./setup.sh

# connect from 172.17.0.2 to 10.110.0.110 (fwd-port: 21122) 
#                         to 10.120.0.120 (fwd-port: 21222)  
# through (172.17.0.4(10.140.0.2) <-> 10.140.0.140(10.110.0.1|10.120.0.1) <-> 10.110.0.110|10.120.0.120):
$ docker exec -it -u tunnel -w /home/tunnel user ssh -p 21122 tunneller@172.17.0.4
$ docker exec -it -u tunnel -w /home/tunnel user ssh -p 21222 tunneller@172.17.0.4
```