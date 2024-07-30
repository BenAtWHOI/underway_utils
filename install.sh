# Uninstall previous OpenRVDAS installation if exists
# (does not remove rvdas user)
./uninstall_openrvdas.sh


# Download and unpack an OpenRVDAS release
INSTALL_ROOT="/opt"
RELEASE_TAG="v1.10.2"
cd $INSTALL_ROOT && git clone https://github.com/OceanDataTools/openrvdas
git checkout tags/${RELEASE_TAG}


# Run its installer script
cd $INSTALL_ROOT/openrvdas/utils && ./install_openrvdas.sh

    
# With the virtualenv activated, pip install a release tag of your script from GitHub
# VENV_PATH=$INSTALL_ROOT/openrvdas/venv
# . $VENV_PATH/bin/activate

echo "export PYTHONPATH=$INSTALL_ROOT/openrvdas:$PYTHONPATH"

pip install git+https://github.com/BenAtWHOI/underway_rvdas