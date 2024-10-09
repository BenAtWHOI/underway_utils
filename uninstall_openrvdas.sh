#!/bin/bash -e

# OpenRVDAS uninstallation script
#
# This script uninstalls OpenRVDAS and removes the configuration
# that was set up by the installation script.
#
# It should be run as root. Please ensure you have the appropriate
# permissions before running this script.

PREFERENCES_FILE='.install_openrvdas_preferences'

function exit_gracefully {
    echo Exiting.
    return -1 2> /dev/null || exit -1
}

#########################################################################
#########################################################################
# Return a normalized yes/no for a value
yes_no() {
    QUESTION=$1
    DEFAULT_ANSWER=$2

    while true; do
        read -p "$QUESTION ($DEFAULT_ANSWER) " yn
        case $yn in
            [Yy]* )
                YES_NO_RESULT=yes
                break;;
            [Nn]* )
                YES_NO_RESULT=no
                break;;
            "" )
                YES_NO_RESULT=$DEFAULT_ANSWER
                break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

###########################################################################
# Read any pre-saved default variables from file
function set_default_variables {
    # Read in the preferences file, if it exists, to overwrite the defaults.
    if [ -e $PREFERENCES_FILE ]; then
        echo "Reading pre-saved defaults from $PREFERENCES_FILE"
        source $PREFERENCES_FILE
    else
        echo "Preferences file not found."
        DEFAULT_INSTALL_ROOT=/opt
        DEFAULT_HOSTNAME=$HOSTNAME
        DEFAULT_HTTP_PROXY=$http_proxy
        DEFAULT_OPENRVDAS_REPO=https://github.com/oceandatatools/openrvdas
        DEFAULT_OPENRVDAS_BRANCH=master
        DEFAULT_NONSSL_SERVER_PORT=80
        DEFAULT_SSL_SERVER_PORT=443
        DEFAULT_RVDAS_USER=rvdas
        DEFAULT_INSTALL_FIREWALLD=no
        DEFAULT_OPENRVDAS_AUTOSTART=yes
        DEFAULT_INSTALL_SIMULATE_NBP=no
        DEFAULT_RUN_SIMULATE_NBP=no
        DEFAULT_SUPERVISORD_WEBINTERFACE=no
        DEFAULT_SUPERVISORD_WEBINTERFACE_AUTH=no
        DEFAULT_SUPERVISORD_WEBINTERFACE_PORT=9001
        DEFAULT_INSTALL_GUI=yes
        DEFAULT_USE_SSL=no
        DEFAULT_HAVE_SSL_CERTIFICATE=no
        DEFAULT_SSL_CRT_LOCATION=
        DEFAULT_SSL_KEY_LOCATION=
        DEFAULT_INSTALL_DOC_MARKDOWN=no
    fi
}

###########################################################################
# Remove the OpenRVDAS installation
function remove_openrvdas {
    yes_no "Remove install root? " yes
    REMOVE_INSTALL_ROOT=$YES_NO_RESULT

    if [ "$REMOVE_INSTALL_ROOT" == "yes" ]; then
        if [ -d $DEFAULT_INSTALL_ROOT/openrvdas ]; then
            echo "Removing OpenRVDAS directory..."
            sudo rm -rf $DEFAULT_INSTALL_ROOT/openrvdas
        else
            echo "OpenRVDAS directory not found."
        fi
    fi
}

###########################################################################
# Remove the user created for OpenRVDAS
function remove_user {
    yes_no "Remove OpenRVDAS user? " yes
    REMOVE_USER=$YES_NO_RESULT

    if [ "$REMOVE_USER" == "yes" ]; then
        if id -u $DEFAULT_RVDAS_USER > /dev/null 2>&1; then
            echo "Removing user $DEFAULT_RVDAS_USER..."
            sudo userdel -r $DEFAULT_RVDAS_USER
        else
            echo "User $DEFAULT_RVDAS_USER does not exist."
        fi
    fi
}

###########################################################################
# Remove the firewall configuration (CentOS/RHEL only)
function remove_firewall {
    if [ $OS_TYPE == 'CentOS' ]; then
        yes_no "Remove firewall configuration? " yes
        REMOVE_FIREWALL_CONFIGURATION=$YES_NO_RESULT

        if [ "$REMOVE_FIREWALL_CONFIGURATION" == "yes" ]; then
            echo "Removing firewall configuration..."
            firewall-cmd -q --permanent --remove-port=${SERVER_PORT}/tcp > /dev/null || echo "No such port ${SERVER_PORT}"
            if [ "$SUPERVISORD_WEBINTERFACE" == 'yes' ]; then
                firewall-cmd -q --permanent --remove-port=${SUPERVISORD_WEBINTERFACE_PORT}/tcp > /dev/null || echo "No such port ${SUPERVISORD_WEBINTERFACE_PORT}"
            fi
            if [ ! -z "$TCP_PORTS_TO_OPEN" ]; then
                for PORT in "${TCP_PORTS_TO_OPEN[@]}"; do
                    firewall-cmd -q --permanent --remove-port=$PORT/tcp > /dev/null || echo "No such port $PORT"
                done
            fi
            if [ ! -z "$UDP_PORTS_TO_OPEN" ]; then
                for PORT in "${UDP_PORTS_TO_OPEN[@]}"; do
                    firewall-cmd -q --permanent --remove-port=$PORT/udp > /dev/null || echo "No such port $PORT"
                done
            fi
            firewall-cmd -q --reload > /dev/null
        fi
    fi
}

###########################################################################
# Remove the supervisor configuration and stop services
function remove_supervisor {
    yes_no "Remove supervisor? " yes
    REMOVE_SUPERVISOR=$YES_NO_RESULT

    if [ "$REMOVE_SUPERVISOR" == "yes" ]; then
        echo "Removing supervisor configuration and stopping services..."
        if [ $OS_TYPE == 'MacOS' ]; then
            SUPERVISOR_DIR=/usr/local/etc/supervisor.d
        elif [ $OS_TYPE == 'CentOS' ]; then
            SUPERVISOR_DIR=/etc/supervisord.d
        elif [ $OS_TYPE == 'Ubuntu' ]; then
            SUPERVISOR_DIR=/etc/supervisor/conf.d
        fi

        sudo rm -f $SUPERVISOR_DIR/openrvdas.*
        sudo rm -f $SUPERVISOR_DIR/openrvdas_logger_manager.*
        sudo rm -f $SUPERVISOR_DIR/openrvdas_cached_data.*
        sudo rm -f $SUPERVISOR_DIR/openrvdas_django.*
        sudo rm -f $SUPERVISOR_DIR/openrvdas_simulate.*

        if [ $OS_TYPE == 'MacOS' ]; then
            sudo pkill supervisord
        elif [ $OS_TYPE == 'CentOS' ]; then
            sudo systemctl stop supervisord || echo "supervisord not running"
            sudo systemctl disable supervisord || echo "supervisord disabled"
        elif [ $OS_TYPE == 'Ubuntu' ]; then
            sudo systemctl stop supervisor || echo "supervisor not running"
            sudo systemctl disable supervisor || echo "supervisor disabled"
        fi
    fi
}

###########################################################################
# Remove the NGINX and UWSGI configuration
function remove_nginx_uwsgi {
    if [[ "$INSTALL_GUI" == "yes" ]]; then
        yes_no "Remove supervisor? " yes
        REMOVE_SUPERVISOR=$YES_NO_RESULT

        if [ "$REMOVE_SUPERVISOR" == "yes" ]; then
            echo "Removing NGINX and UWSGI configuration..."
            if [ $OS_TYPE == 'MacOS' ]; then
                ETC_HOME=/usr/local/etc
            elif [ $OS_TYPE == 'CentOS' ] || [ $OS_TYPE == 'Ubuntu' ]; then
                ETC_HOME=/etc
            fi
            sudo rm -f ${INSTALL_ROOT}/openrvdas/django_gui/openrvdas_nginx.conf
            sudo rm -f ${INSTALL_ROOT}/openrvdas/django_gui/openrvdas_uwsgi.ini
            sudo rm -f $ETC_HOME/uwsgi/vassals/openrvdas_uwsgi.ini
            sudo systemctl stop nginx || echo "nginx not running"
            sudo systemctl disable nginx || echo "nginx disabled"
            sudo systemctl stop uwsgi || echo "uwsgi not running"
            sudo systemctl disable uwsgi || echo "uwsgi disabled"
        fi
    fi
}

###########################################################################
# Remove SSL certificates if they are self-signed
function remove_ssl_certificate {
    yes_no "Remove ssl certificate? " yes
    REMOVE_SSL_CERTIFICATE=$YES_NO_RESULT

    if [ "$REMOVE_SSL_CERTIFICATE" == "yes" ]; then
        if [[ $USE_SSL == "yes" ]] && [[ $HAVE_SSL_CERTIFICATE == 'no' ]]; then
            echo "Removing SSL certificates..."
            sudo rm -f $SSL_CRT_LOCATION $SSL_KEY_LOCATION
        fi
    fi
}

###########################################################################
# Remove virtual environment and Python packages
function remove_python_packages {
    yes_no "Remove python packages? " yes
    REMOVE_PYTHON_PACKAGES=$YES_NO_RESULT

    if [ "$REMOVE_PYTHON_PACKAGES" == "yes" ]; then
        echo "Removing Python virtual environment..."
        sudo rm -rf $INSTALL_ROOT/openrvdas/venv
    fi
}

###########################################################################
# Remove markdown rendering setup
function remove_markdown {
    if [[ $INSTALL_DOC_MARKDOWN == 'yes' ]]; then
        yes_no "Remove markdown? " yes
        REMOVE_MARKDOWN=$YES_NO_RESULT

        if [ "$REMOVE_MARKDOWN" == "yes" ]; then
            echo "Removing Strapdown.js..."
            sudo rm -rf ${INSTALL_ROOT}/openrvdas/static/Strapdown.js
        fi
    fi
}

###########################################################################
# Remove log and tmp directories
function remove_logs_and_tmp {
    yes_no "Remove log and temporary directories? " yes
    REMOVE_LOG_TMP=$YES_NO_RESULT

    if [ "$REMOVE_LOG_TMP" == "yes" ]; then
        echo "Removing log and temporary directories..."
        sudo rm -rf /var/log/openrvdas /var/tmp/openrvdas
    fi
}

###########################################################################
###########################################################################
###########################################################################
# Start of actual script
###########################################################################
###########################################################################

echo
echo "OpenRVDAS uninstallation script"

# Read from the preferences file in $PREFERENCES_FILE, if it exists
set_default_variables

# Set OS_TYPE to either MacOS, CentOS or Ubuntu
if [[ `uname -s` == 'Darwin' ]]; then
    OS_TYPE=MacOS
elif [[ `uname -s` == 'Linux' ]]; then
    if [[ ! -z `grep "NAME=\"Ubuntu\"" /etc/os-release` ]]; then
        OS_TYPE=Ubuntu
    elif [[ ! -z `grep "NAME=\"CentOS\"" /etc/os-release` ]] || [[ ! -z `grep "NAME=\"Red Hat Enterprise Linux\"" /etc/os-release` ]]; then
        OS_TYPE=CentOS
    else
        echo "Unknown Linux variant!"
        exit_gracefully
    fi
else
    echo Unknown OS type: `uname -s`
    exit_gracefully
fi

# Start uninstallation
remove_openrvdas
remove_user
remove_firewall
remove_supervisor
remove_nginx_uwsgi
remove_ssl_certificate
remove_python_packages
remove_markdown
remove_logs_and_tmp

echo
echo "Uninstallation complete. Goodbye!"
