#!/bin/bash



# Function : Returns key after being given name in secure enclave
# Variables : $s1 - name of key wanted to be found

clean_key_list() {
	key_list=$(sekey --list-keys)
	key_id_input=$(echo $1 | sed 's/[^a-zA-Z0-9,]//g')

	i=0

	while read -r line; do
  		new_line=$(echo $line | sed 's/ \│ /,/g;s/[^a-zA-Z0-9,]//g')
  		local key_id=$(echo "$new_line" | sed 's/,.*//')
        echo "$key_id" >&2
  		if test -z "$new_line"; then
  			continue; else
  				if [[ "$key_id" == "$key_id_input" ]]; then
  					private_key=$(echo "$new_line" | sed 's/.*,\(.*\)/\1/')
  					echo "$private_key"
  					return 1
  				fi
		fi
	done <<< "$key_list"
	return 0 
}


echo """
This is a script to add Sekey to let you use touchID in place of a yubikey. 

Refer to: https://github.com/sekey/sekey for further documentation on sekey.

\n"""

read -p 'Install sekey and setup touchID ssh? [y/n]' option

read -p 'Server Username (on blair): ' username

if [ 'y' == ${option:0:1} ]; then
	brew install --cask sekey
else
	exit 'Program aborted'
fi

if [ "$(tail -1 ~/.zshrc)" != "export SSH_AUTH_SOCK=\$HOME/.sekey/ssh-agent.ssh"  ]; then
	echo "export SSH_AUTH_SOCK=\$HOME/.sekey/ssh-agent.ssh" >> ~/.zshrc
fi

# sekey --generate-keypair "Blair Key"

sleep 2

private_key="$(clean_key_list "Blair Key")"

echo "$private_key"

echo "$(sekey --export-key $private_key)" > ~/.ssh/blair.pub

sleep 2

FILE=~/.ssh/config
if [ ! -f "$FILE" ]; then
    touch ~/.ssh/config
fi

blair_text=""" 
Host github.com
	User ${username}
	Hostname github.com
	IdentityFile ~/.ssh/blair.pub
	IdentitiesOnly yes
""" 

#if grep -Fxq -m 1 "$blair_text" "$FILE"; then
#	echo ""
#else
#	echo "$blair_text" >> "$FILE"
#fi

echo "$blair_text" >> "$FILE"

#cat /dev/null > ~/.bash_history

echo """
To finalise, add the public ssh key found at ~/.ssh/blair.pub to blair and you're done! 

"""
