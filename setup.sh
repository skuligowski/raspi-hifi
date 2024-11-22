#!/bin/bash
# setup.sh - Script to configure IQAudio PiAmp and Raspotify on Raspberry Pi


CONFIG_FILE="/boot/firmware/config.txt"
#CONFIG_FILE="./test/config.txt"
RASPOTIFY_FILE="/etc/raspotify/conf"
#RASPOTIFY_FILE="./test/conf"
RASPOTIFY_NAME="Pi Speaker"


echo ">>> Downloading files"
sudo apt-get -y install curl
curl -sSL https://raw.githubusercontent.com/skuligowski/raspi-hifi/refs/heads/main/piconfig.txt -o piconfig.txt
curl -sSL https://raw.githubusercontent.com/skuligowski/raspi-hifi/refs/heads/main/speaker-agent.py -o speaker-agent.py
curl -sSL https://raw.githubusercontent.com/skuligowski/raspi-hifi/refs/heads/main/speaker-agent.service -o speaker-agent.service

echo "[pi] Download completed"

create_backup() {
  configfile=$(basename -- "$1")
  configext="${configfile##*.}"
  configbase="${configfile%.*}"
  configbak="bak/$configbase.$configext.bak"
  echo "[pi] creating backup $1 -> $configbak"
  mkdir -p bak && cp $1 $configbak
}

get_sink() {
  wpctl status | 
  awk 'BEGIN { A=0; S=0; }
      /^Audio/ { A=1; }
      /Sinks/ { S=1; }
      /Sink endpoints/ { S=0; }
      /^Video/ { A=0; }
      { if (A==1 && S==1 && / *\* *[[:digit:]]*\./) 
      { print; } }' |
  sed 's/^.* \([[:digit:]]*\)\. \(.*\) \[.*$/\1/'
}

echo ">>> Configuring IQAudio PiAmp in $CONFIG_FILE..."

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: $CONFIG_FILE not found."
  exit 1
fi

create_backup $CONFIG_FILE

echo "[pi] disabling dtparam=audio=on"
sudo sed -i 's/^dtparam=audio=on/#dtparam=audio=on/' "$CONFIG_FILE"

allheader=false
cat piconfig.txt | while read line 
do
   found=$(grep "^$line" "$CONFIG_FILE")
   if [ -z $found ]; then
    if [ $allheader = false ]; then
      echo "" | sudo tee -a "$CONFIG_FILE"
      echo "[all]" | sudo tee -a "$CONFIG_FILE"
      allheader=true
    fi
    echo "[pi] adding $line"
    echo "$line" | sudo tee -a "$CONFIG_FILE"
  fi
done


echo ">>> Installing Pipewire and Wireplumber"

sudo apt update
sudo apt -t bookworm install pipewire wireplumber libspa-0.2-bluetooth
sudo apt install python3-dbus

cp speaker-agent.py ~
mkdir -p ~/.config/systemd/user
cp speaker-agent.service ~/.config/systemd/user
systemctl --user enable speaker-agent.service

sudo sed -i 's/#JustWorksRepairing.*/JustWorksRepairing = always/' /etc/bluetooth/main.conf

echo "Settings default volumen"
sink_id=$(get_sink)
echo "Sink id: $sink_id"
wpctl set-volume $sink_id 80%
wpctl status

echo ">>> Installing Raspotify..."

sudo curl -sL https://dtcooper.github.io/raspotify/install.sh | sh

echo ">>> Configuring Raspotify..."

create_backup $RASPOTIFY_FILE
sed -i "s/#LIBRESPOT_NAME=.*/LIBRESPOT_NAME=\"${RASPOTIFY_NAME}\"/g" "${RASPOTIFY_FILE}"
sed -i 's/#LIBRESPOT_BITRATE=.*/LIBRESPOT_BITRATE="320"/g' "${RASPOTIFY_FILE}"

