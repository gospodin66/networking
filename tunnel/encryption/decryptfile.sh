#!/bin/sh
plain_file="./files/dec_passwords"
encrypted_file="./files/enc_passwords.gpg"

#echo "Decrypting file [$(realpath $encrypted_file)]"
out=$(gpg --pinentry-mode loopback --no-verbose --quiet --decrypt $encrypted_file 2>/dev/null)

echo $out