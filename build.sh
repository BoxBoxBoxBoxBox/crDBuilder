#!/usr/bin/env bash

# Create dir for rom
mkdir -p /ci/crdroid

# Switch dir
cd /ci/crdroid

# Sync rom
repo init --depth=1 --no-repo-verify -u https://github.com/crdroidandroid/android.git -b 12.1 -g default,-mips,-darwin,-notdefault
git clone https://github.com/crdroid-lava/Manifest.git --depth 1 -b 12.1 .repo/local_manifests
repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j$(nproc --all) || repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j$(nproc --all)

# Change some repos
rm -rf vendor/crDroidOTA
rm -rf packages/apps/Updater
git clone --depth 1 https://github.com/orkunergun/crDroidOTA -b 12.1 vendor/crDroidOTA
git clone --depth 1 https://github.com/orkunergun/crDroid-Updater -b 12.1 packages/apps/Updater

# Export commands
export _JAVA_OPTIONS="-Xmx10g"
export CCACHE_DIR=/ci
export CCACHE_EXEC=$(which ccache)
export USE_CCACHE=1
ccache -M 15G
ccache -o compression=true
ccache -z

# Build commands
source build/envsetup.sh
lunch lineage_lava-userdebug
export SELINUX_IGNORE_NEVERALLOWS=true
export TZ=Asia/Dhaka

# Compile command
compile_plox () {
make bacon -j$(nproc --all)
}

# Lets Make Full Rom
compile_plox | tee build.log
if [ ! -e out/target/product/*/*2022*.zip ]; then # to bypass OOM kill
sed -i 's/-j$(nproc --all)/-j7/' /ci/build.sh
. /ci/build.sh # run again to update values before starting compilation
compile_plox # simply re-run the build with less threads
fi
if [ ! -e out/target/product/*/*2022*.zip ]; then
sed -i 's/-j7/-j6/' /ci/build.sh
. /ci/build.sh
compile_plox # just incase if -1 thread didnt help
fi
if [ -e "/ci/crdroid/build.log" ] && [ $(tail -n 90 /ci/crdroid/build.log | grep -o -e 'build stopped' -e 'FAILED: ' | head -n 1) ]; then
echo "" > /ci/crdroid/abort_loop.txt # will use it as guard for failed builds
fi

# Change dir again for upload
cd out/target/product/lava/
export OUTPUT="crDroid*.zip"
FILENAME=$(echo $OUTPUT)

# Config for oshi.at
if [ -z "$TIMEOUT" ];then
    TIMEOUT=20160
fi

# Upload to WeTransfer
transfer wet $FILENAME > link.txt || { echo "ERROR: Failed to Upload the Build!" && exit 1; }

# Mirror to oshi.at
curl -T $FILENAME https://oshi.at/${FILENAME}/${OUTPUT} > mirror.txt || { echo "WARNING: Failed to Mirror the Build!"; }

DL_LINK=$(cat link.txt | grep Download | cut -d\  -f3)
MIRROR_LINK=$(cat mirror.txt | grep Download | cut -d\  -f1)

# Show the Download Link
echo "=============================================="
echo "Download Link: ${DL_LINK}" || { echo "ERROR: Failed to Upload the Build!"; }
echo "Mirror: ${MIRROR_LINK}" || { echo "WARNING: Failed to Mirror the Build!"; }
echo "=============================================="

# Remove 
rm -rf out/target/product/lava
