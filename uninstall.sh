#!/bin/bash

if [ -f build/install_manifest.txt ]; then
   echo "Uninstallation file exists..."
   sudo xargs -d '\n' rm < build/install_manifest.txt
else
   echo "Uninstallation file does not exist."
fi
