#!/bin/bash
# Activation script for the backend virtual environment
# Usage: source activate.sh

echo "Activating Python virtual environment..."
source venv/bin/activate
echo "Virtual environment activated!"
echo "You can now run: python app.py"
echo "Or use: make run (to install dependencies and start)"
