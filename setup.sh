#!/bin/bash

set -o errexit
set -o pipefail
#set -o xtrace # debug

DOCKERINSTALLER='dockerInstaller'
ANY_CONNECT_INSTALLER='anyconnect-macos-4.9.05042-predeploy-k9'
MYSQL_QUERY_STRING=""
SELECTED_ENVIRONMENT=""
SELECTED_DB=""
MYSQL_QUERY_STRING="ls -l"
DOCKER='Docker'
INTEL='Intel'
VAULT_TOKEN=~/.vault-token
ARCH_NAME="$(uname -m)"
GIT_INSTALLER="gitInstaller"


#######FUNCTIONS
spaces() {
  echo ""
}

validate_architecture() {
if [ "${ARCH_NAME}" = "x86_64" ]; then
    if [ "$(sysctl -in sysctl.proc_translated)" = "1" ]; then
        echo "Rosetta 2"
    else
        echo ${INTEL}
    fi 
elif [ "${ARCH_NAME}" = "arm64" ]; then
    echo 'ARM'
else
    echo 'Unknown architecture: ${ARCH_NAME}'
fi
}
#######END FUNCTIONS

echo "
  _______  ____     _____                                    _     _______                      
 |__   __||___ \   / ____|                                  | |   |__   __|                     
    | |     __) | | (___   _   _  _ __   _ __    ___   _ __ | |_     | |  ___   __ _  _ __ ___  
    | |    |__ <   \___ \ | | | || '_ \ | '_ \  / _ \ | '__|| __|    | | / _ \ / _` || '_ ` _ \ 
    | |    ___) |  ____) || |_| || |_) || |_) || (_) || |   | |_     | ||  __/| (_| || | | | | |
    |_|   |____/  |_____/  \__,_|| .__/ | .__/  \___/ |_|    \__|    |_| \___| \__,_||_| |_| |_|
                                 | |    | |                                                     
                                 |_|    |_|                                                     
"
echo "Hello, ${USER}"

spaces

[[ $(uname) == 'Darwin' ]] || {
	echo "This script only runs on macOS." >&2; 
	exit 2; 
}

spaces
 
echo "<<<Step 1: Installing Docker Desktop>>"
if [[ $(command -v Docker) != *'Docker'* ]]; then
  if [ $(validate_architecture) = "${INTEL}" ]; then
    ##Intel Processor
    curl "https://desktop.docker.com/mac/main/amd64/Docker.dmg?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-mac-amd64" > ${DOCKERINSTALLER}.dmg
    echo "++Debug: docker installer name" ${DOCKERINSTALLER}
    sudo hdiutil attach ${DOCKERINSTALLER}.dmg
    sudo cp -fRv "/Volumes/Docker/Docker.app" /Applications
    #echo <password> | sudo -S
  else
    ##ARM Processor
    curl "https://desktop.docker.com/mac/main/arm64/Docker.dmg?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-mac-arm64" > ${DOCKERINSTALLER}.dmg
  fi
fi

spaces

echo "<<<Step 2: Installing google SDK!>>"
curl https://sdk.cloud.google.com > googleSdkInstaller.sh
echo "Write directory path to install sdk.cloud.google: "
read gcloudSdkDirectory
echo "++Debug: This directory" ${gcloudSdkDirectory}s
bash install.sh --disable-prompts --install-dir=${gcloudSdkDirectory}
echo "++Debug: listing files in the destination directory: " ${gcloudSdkDirectory}

spaces

echo "<<<Step 3: Configuring Broad VPN Access>>"
echo "Go to http://vpn.broadinstitute.org/"
echo "Do login using your BROAD'S Account"
echo "Be sure that you are connected in the group <<Z-Duo-Broad-NonSplit-VPN>>"
echo 'Follow the instructions to install the VPN client in https://"https://vpn.broadinstitute.org/CACHE/stc/3/index.html#:~:text=Download-,for,-macOS"'

spaces

echo "<<Step 4: docker hub account creation>>"
echo "Create a new acount following the next link https://hub.docker.com"
echo "Validate your account in your BROAD's email account"

spaces

echo "<<<Step 5: Installing git>>"
if [[ $(command -v Git) != *'Git'* ]]; then
  curl https://repo.huaweicloud.com/git-for-macos/git-2.15.0-intel-universal-mavericks.dmg > ${GIT_INSTALLER}.dmg
  #echo "++Debug: docker installer name ${GIT_INSTALLER}" 
  sudo hdiutil attach ${GIT_INSTALLER}.dmg
  sudo cp -fRv "/Volumes/Git 2.15.0 Mavericks Intel Universal/git-2.15.0-intel-universal-mavericks.pkg" /Applications
fi

spaces

echo "<<<Step 6: Configuring github>>"
echo "
<Join to Github>
1. Create a new account on github
2. Visit: https://github.broadinstitute.org and follow the instructions
3. Go to github Slack channel, click on the lightning bolt icon below the Message field, and select “Join DataBiosphere”.
This is to give permission for working with repositories in https://github.com/DataBiosphere.
When you get a Slackbot notification that you have been added, follow the link and accept the invitation.
https://github.com/broadinstitute/
Being added to dsp-engineering group is (next-day) automatic after joining the Google group.
To join the group, you will need to ask a manager to add the new team member.
Make sure this is done by the end of the first day.
"

spaces

echo "<<<Step 7: Generate github key>>
1. Go to: https://github.com/settings/tokens
2. Generate a new token selecting the next options:
  - workflow
  - admin:org only read:org
  - gist
  - user (all checks)
3. Copy the generated key
"

spaces

echo "<<<Step 8: Configuring github token>>"
echo "Paste here your generated github key:"
read -s GIT_KEY
echo "${GIT_KEY}" > ~/.github-token
echo "Successfully resgistered this key: <<"`cat ~/.github-token`">>"

spaces

echo "<<<Step 9: Configuring vault locally>>"
echo "--Ensure that you are connected to the broad's VPN--"
docker run -it --rm -v $HOME:/root:rw broadinstitute/dsde-toolbox:dev vault auth -method=github token=$(cat ~/.github-token)
if test -f "$VAULT_TOKEN"; then
    echo "Vault token generated successfully."
    else
      echo "Error generating valult token"
fi

spaces

echo "<<<Step 10 Generate SSH key for GitHub repository>>"
echo "Write your broad's email account in format 'user@broadinstitute.org"
read BROAD_EMAIL
ssh-keygen -t rsa -b 4096 -C "${BROAD_EMAIL}"
echo "Generated the SSH key:  ${BROAD_EMAIL}"
echo "Copy the generated public key (the one with .pub extension) and paste it in the next link: 'https://github.com/settings/keys' (being you logged with your github accout) and doing click in 'New SSH key'"

spaces

echo "<<<Step 11: Downloading command line tools from GitHub>>"
echo "Write the location of your new git repository directory:  example: '/Volumes/HD/Documents/broad/repository'"
read LOCAL_GITHUB_REPO
mkdir ${LOCAL_GITHUB_REPO}
cd ${LOCAL_GITHUB_REPO}
git clone git@github.com:broadinstitute/dsp-scripts.git

spaces

echo "<<<Step 11: Configuring mysql access>>"
echo "Select the DB environment:"

while true; do
echo "<1> prod"
echo "<2> dev"
echo "<0> exit"
echo 

echo -n "Enter the number of your choice: "
read DB_ENV_CHOICE
echo

case $DB_ENV_CHOICE in 
       1)
	   echo "${MYSQL_QUERY_STRING}"
	   ${MYSQL_QUERY_STRING}
	   SELECTED_ENVIRONMENT="prod"
	   break
       ;;
       2)
	   SELECTED_ENVIRONMENT="dev"
	   break
       ;;
       3)
	   SELECTED_ENVIRONMENT="exit"
	   break
       ;;
       0)
       echo "Bye!!"
       break
       ;;
       *)
       echo "Invalid choice, try a number from 0 to 3."
       ;;
esac
done

spaces

#echo ++Debug Selected environment: "${SELECTED_ENVIRONMENT}"

echo "Select the DB to connect: "

while true; do
echo "<1> Leonardo"
echo "<2> Rawsl"
echo "<3> Cromwell"
echo "<0> exit"
echo 

echo -n "Enter the number of your choice: "
read DB_CHOICE
echo

case $DB_CHOICE in 
       1)
	   SELECTED_DB="leonardo"
	   echo "${MYSQL_QUERY_STRING}"
       break
	   ;;
       2)
       SELECTED_DB="rawls"
	   break
       ;;
       3)
       SELECTED_DB="cromwell"
	   break
       ;;
       0)
       echo "Bye!!"
       break
       ;;
       *)
       echo "Invalid choice, try a number from 0 to 3."
       ;;
esac
done

echo ++Debug Selected DB: "${SELECTED_DB}"

MYSQL_QUERY_STRING="docker run -it --rm -v ${HOME}:/root broadinstitute/dsde-toolbox:dev mysql-connect.sh -p firecloud -e ${SELECTED_ENVIRONMENT} -a  ${SELECTED_DB}"

#echo ++debug ${MYSQL_QUERY_STRING}

#${MYSQL_QUERY_STRING}

spaces

echo "<<<Step 13: Install brew>>"
if [[ $(command -v brew) != *'brew'* ]]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

spaces

echo "<<<Step 14: Install jq>>"
if [[ $(command -v jq) != *'jq'* ]]; then
  brew install jq
fi

spaces

echo "<<<Step 15: Configuring github SAM DB Access>>"
#Allow tabs execution
echo "When the system prompt about enable console control mark the corresponding check and Accept"
cd "${LOCAL_GITHUB_REPO}/dsp-scripts/firecloud"
osascript \
  -e 'tell application "Terminal" to activate' \
  -e 'tell application "System Events" to tell process "Terminal" to keystroke "t" using command down' \
  -e 'tell application "Terminal" to do script "cd '${LOCAL_GITHUB_REPO}/dsp-scripts/firecloud' && ./psql-connect.sh prod sam" in selected tab of the front window'
