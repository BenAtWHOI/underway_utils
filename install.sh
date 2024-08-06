#!/bin/bash

INSTALL_ROOT="/opt"
VENV_PATH=$INSTALL_ROOT/openrvdas/venv
OPENRVDAS_RELEASE_TAG="v1.10.2"
WHOI_IMPLEMENTATION_RELEASE_TAG="v0.2.3"

# Uninstall any existing OpenRVDAS installation (does not remove rvdas user)
./uninstall_openrvdas.sh

# Download an OpenRVDAS release, run the install script, and checkout the tag
cd $INSTALL_ROOT && git clone https://github.com/OceanDataTools/openrvdas
cd $INSTALL_ROOT/openrvdas/utils && ./install_openrvdas.sh
cd $INSTALL_ROOT/openrvdas && git checkout tags/${OPENRVDAS_RELEASE_TAG}

# With the virtualenv activated, pip install a release tag of the WHOI implementation
. $VENV_PATH/bin/activate && pip install git+https://github.com/BenAtWHOI/underway_rvdas@$WHOI_IMPLEMENTATION_RELEASE_TAG
echo "export PYTHONPATH=\"$PYTHONPATH:$INSTALL_ROOT/openrvdas\"" >> "$VENV_PATH/bin/activate"

# Prompt to activate venv
echo
echo "To run the underway data monitor, execute the following commands:"
echo " . $VENV_PATH/bin/activate"
echo " underway_rvdas <configuration options>"