#!/bin/bash

source .env

echo "Loading virtual environment"
source $TEST_VENV_ACTIVATE_PATH

echo "Starting data simulation"
cd $TEST_OPENRVDAS_UTILS_PATH && python3 simulate_data.py --config $TEST_SIMULATE_DATA_CONFIG_PATH &

sleep 5
echo "Starting feeder scripts"
cd $TEST_FEEDER_SCRIPTS_PATH && ./startup.sh

sleep 5
echo "Running underway data monitor"
underway_rvdas --ship test &

deactivate