#!/bin/sh

# ./gen-key-enrypt-file.sh .pconfig

argc=$#

if [ "$argc" -lt 1 ]; then
    echo "Please enter <config_file> argument."
    exit 1
fi

config_file="$1"

if [ ! -f "$config_file" ]; then
    echo "Error: Config file not found."
    exit 1
fi

source "$config_file"

read -sp 'Passphrase: ' passphrase
echo "Generating key from batch.."

cat > key_details <<EOF
    %echo Generating a basic OpenPGP key
    Key-Type: $P_KEY_TYPE
    Key-Length: $P_KEY_LEN
    Subkey-Type: $P_KEY_TYPE
    Subkey-Length: $P_KEY_LEN
    Name-Real: $P_REALNAME
    Name-Comment: "$P_COMMENT"
    Name-Email: $P_RECIPIENT_EMAIL
    Expire-Date: $P_KEY_EXPIRE
    Passphrase: $passphrase
    %commit
    %echo done
EOF
gpg -vvv --batch --generate-key key_details

echo "Encrypting file [$(realpath $P_PLAIN_FILE)]"
gpg --encrypt \
    --armor \
    --output $P_ENC_FILE \
    --recipient $P_RECIPIENT_EMAIL \
    $P_PLAIN_FILE

echo "$P_PLAIN_FILE" | /usr/bin/expect -c '
    puts "Removing plaintext file & key_details file.."
    set plaintext_file [gets stdin]; 
    spawn rm $plaintext_file 
    expect -re "rm: remove*?"
    send "y\r"
    expect eof
    puts "Plaintext file removed successfuly."
'

echo -e "Done!\n"
exit 0