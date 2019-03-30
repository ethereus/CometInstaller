#!/bin/sh
# RootlessInstallerInstaller (Credits)
# Comet Installer

# Kill application
killall -9 Runner
# Copy application
COMET=$0
COMET=${COMET%/*}
cp -R $COMET /var/Apps/Runner.app
rm -rf ${COMET%/*}
COMET="/var/Apps/Runner.app"
# Install application
jtool --sign --inplace --ent "$COMET/ent.xml" "$COMET/Runner"
uicache
COMET=$(find /var/containers/Bundle/Application | grep Runner.app/Runner)
inject $COMET
chown root $COMET
chmod 6755 $COMET
# Finished
echo "Installed Comet!"
echo "Enjoy! :-)"
echo "Credits to: RootlessInstaller, Chr0nic"
