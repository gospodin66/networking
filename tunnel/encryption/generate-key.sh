#!/bin/sh

passphrase="tunnel"

keytype="RSA"
key_len=4096
realname="SSH-Tunnel"
recipient_email=<recipient_email>
expire_date=0

cat > key_details <<EOF
    %echo Generating a basic OpenPGP key
    Key-Type: $keytype
    Key-Length: $key_len
    Subkey-Type: $keytype
    Subkey-Length: $key_len
    Name-Real: $realname
    Name-Comment: "Key for authenticating ssh tunnel."
    Name-Email: $recipient_email
    Expire-Date: $expire_date
    Passphrase: $passphrase
    %commit
    %echo done
EOF


echo "Generating key from batch.."
gpg -vvv --batch --generate-key key_details

rm key_details

#echo ">>> Revoke certificate is generated automatically."
#gpg --output eni-tunnel-revoke.asc --gen-revoke $realname

exit 0