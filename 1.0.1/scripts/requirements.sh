#!/bin/bash

# check if this is an automate build not ask any questions
[ "$CI" = "true" ] && AUTOMATE_BUILD="true"

# Variables
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
STATUS="OK"
DOCKER_SOCK="/var/run/docker.sock"


# Load Variables from Configuration
[ -e "$SCRIPTPATH/../.env" ] && source $SCRIPTPATH/../config/config.env

# to add options to the echo command
    echo () {
        command echo -e "$@" 
    }

####################    Start Script    ##############################

#
#   Check DOCKER
#
    if [ -z "$(which docker)" ] 
        then
            STATUS="FAIL"
            echo "[FAIL] Docker is not Installed. \tPlease install it first!" 
        else
            echo "[OK] Docker is Installed. \t\tOutput: $(docker -v)"   
    fi

#
#   Check GIT
#
    if [ -z "$(which git)" ] 
        then
            STATUS="FAIL"
            echo -e "[FAIL] Git is not Installed. \t\t\tPlease install it first!"
        else
            echo -e "[OK] Git is Installed. \t\t\tOutput: $(git --version)"
    fi

#
# CHECK required URLs
#
echo
# check_URL: check a url with 2 parameters: URL_BASE=github.com & URL_PROTOCOL=http/https
function check_URL(){
    #set -xv
    URL="$1"
    [ "$USE_PROXY" == "yes" ] && PROXY=" -x $HTTP_PROXY"
    OPTIONS="-vs --connect-timeout 60 -m 30 $PROXY"
    COMMAND="$(curl $OPTIONS $URL 2>&1|grep 'Connected to')"
    
    if [ -z "$COMMAND" ]
        then
            echo "[WARN] Check: $URL"
            echo "       Result: Connection not available."
            #[ "$AUTOMATE_BUILD" == "true" ] || read -r -p "     continue with ENTER"  
        else
            echo "[OK]   Check: $URL"
            echo "       Result: $COMMAND."
    fi
}

check_URL https://misp.dcso.de
check_URL https://dockerhub.dcso.de/v2/
check_URL https://github.com/DCSO/misp-dockerized
check_URL https://github.com/misp/misp

###############################  USER CHECKS    #########################
echo "" # Empty Line for a better overview.

#
#   Check user part of docker group
#
    if [ $(whoami) != "root" ]
        then
            # if user is not root then check if it is in dokcer group
            if [ -z "$(cat /etc/group|grep docker|grep `whoami`)" ]
                then
                    STATUS="FAIL"
                    # user not part of docker group
                    echo "[FAIL] User '$(whoami)' isn't part of the docker group. -> Try: sudo usermod -aG docker $(whoami)"
                else
                    # user is in docker group
                    echo "[OK] User '$(whoami)' is part of the docker group."
            fi
        else
            echo "[OK] User '$(whoami)' has root rights."
    fi
#
#   Check docker.sock
#
    if [ ! -z "$(docker ps 2>&1|grep 'permission denied')" ]
        then
            STATUS="FAIL"
            echo "[FAIL] User '$(whoami)' hasn't access to Docker."
        else
            # user is in docker group
            echo "[OK] User '$(whoami)' has access to Docker."
    fi

###############################  FILE CHECKS    #########################

#
#   Check Write permissions
#
echo
[ ! -d ./config/ssl ]     && echo -n "create config and config/ssl directory..." && mkdir -p ./config/ssl  && echo "finished." 
[ ! -d ./config/smime ]   && echo -n "create config/smime directory..."          && mkdir ./config/smime         && echo "finished."
[ ! -d ./config/pgp ]     && echo -n "create config/pgp directory..."            && mkdir ./config/pgp         && echo "finished."
[ ! -d ./backup ]         && echo -n "create backup directory..."                && mkdir ./backup         && echo "finished."

function check_folder(){
    FOLDER="$1"
    if [ ! -e "$FOLDER" ]
            then
                STATUS="FAIL"
                echo "[FAIL] Can't create '$FOLDER' Folder."
            else
                # user is in docker group
                echo "[OK] Folder $FOLDER exists."
                touch $FOLDER/test
                if [ ! -e $FOLDER/test ]
                    then
                        STATUS="FAIL"
                        echo "[FAIL] No write permissions in '$FOLDER'. Please ensure that user '${whoami}' has write permissions.'"
                    else
                        echo "[OK] Testfile in '$FOLDER' can be created."
                        rm $FOLDER/test
                fi
        fi
}

check_folder "config"
check_folder "config/ssl"
check_folder "config/pgp"
check_folder "config/smime"
check_folder "backup"



###############################  SSL CERT CHECKS    #########################
echo
if [ ! -f ./config/ssl/key.pem -a ! -f ./config/ssl/cert.pem ]; then
    echo "[WARN] No SSL certificate found. We create a self-signed certificate in the volume."
    echo "     To change the SSL certificate and private key later: "
    echo "     1. save certificate into:      $PWD/config/ssl/cert.pem"
    echo "     2. save private keyfile into:  $PWD/config/ssl/key.pem"
    echo "     3. do:                         make configure"
    echo
    echo
fi

###############################  SMIME CHECKS    #########################
echo
if [ ! -f ./config/smime/key.pem -a ! -f ./config/smime/cert.pem ]; then
    echo "[WARN] No S/MIME certificate found."
    echo "     1. Please save your cert at:  $PWD/config/smime/cert.pem" 
    echo "     2. Please save your key  at:  $PWD/config/smime/key.pem"
    echo "     3. do:                        make config-server"
    echo
fi

###############################  PGP CHECKS    #########################
echo
if [ ! -f ./config/pgp/private.key -a ! -f ./config/pgp/public.key ]; then
    echo "[WARN] No PGP key found."
    echo "     To replace the PGP public and private file later: "
    echo "     1. save public key into:      $PWD/config/pgp/public.key"
    echo "     2. save private key into:  $PWD/config/pgp/private.key"
    echo "     3. do:                         make config-server"
    echo
    echo
fi

###############################  END Result    #########################
echo "End result:"
if [ $STATUS == "FAIL" ]
    then
        echo "[$STATUS] at least one Error is occured."
        echo
        exit 1
    else
        echo "[$STATUS] no Error is occured."
        echo
        exit 0
fi
##########################################################################