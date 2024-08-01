
INSTALL_ROOT="/opt"
RELEASE_TAG="v1.10.2"
VENV_PATH=$INSTALL_ROOT/openrvdas/venv
WHOI_IMPLEMENTATION_VERSION="v0.2.2"

# Uninstall previous OpenRVDAS installation if exists
# (does not remove rvdas user)
./uninstall_openrvdas.sh

# Download and unpack an OpenRVDAS release
cd $INSTALL_ROOT && git clone https://github.com/OceanDataTools/openrvdas
git checkout tags/${RELEASE_TAG}

# Run its installer script
cd $INSTALL_ROOT/openrvdas/utils && ./install_openrvdas.sh

# With the virtualenv activated, pip install a release tag of the WHOI implementation
. $VENV_PATH/bin/activate
export PYTHONPATH=$INSTALL_ROOT/openrvdas:$INSTALL_ROOT/openrvdas/logger:$PYTHONPATH
PYTHONPATH=$PYTHONPATH pip install git+https://github.com/BenAtWHOI/underway_rvdas@$WHOI_IMPLEMENTATION_VERSION
echo 'export PYTHONPATH="$INSTALL_ROOT/openrvdas/logger:$INSTALL_ROOT/openrvdas/:$PYTHONPATH"' >> "$VENV_PATH/bin/activate"

# Prompt to activate venv
echo
echo "To run underway_rvdas, execute the following commands:"
echo " . $VENV_PATH/bin/activate"
echo " underway_rvdas <configuration options>"