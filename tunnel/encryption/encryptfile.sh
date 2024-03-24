#!/bin/sh
plain_file="./files/passwords"
encrypted_file="./files/enc_passwords.gpg"
recipient=<recipient_email>

echo "Encrypting file [$(realpath $plain_file)]"
gpg --encrypt \
    --sign \
    --armor \
    --output $encrypted_file \
    --recipient $recipient \
    $plain_file

echo -e "Done!\n"
exit 0