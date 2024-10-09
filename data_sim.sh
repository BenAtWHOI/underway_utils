#!/bin/bash

# Activate virtual environment
source /opt/openrvdas/venv/bin/activate

# Simulate data
cd /opt/openrvdas/logger/utils && python3 simulate_data.py --config /home/befo/Desktop/WHOI/underway/underway_utils/data_sim_config.yaml &