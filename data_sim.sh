#!/bin/bash

source .env

cd $OPENRVDAS_PATH/logger/utils && python3 simulate_data.py --config $SIM_DATA_CONFIG_FILE