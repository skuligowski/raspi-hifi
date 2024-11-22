# raspi-hifi

https://github.com/amondit/raspberry-pipewire-speaker
https://www.collabora.com/news-and-blog/blog/2022/09/02/using-a-raspberry-pi-as-a-bluetooth-speaker-with-pipewire-wireplumber/
https://github.com/fdanis-oss/pw_wp_bluetooth_rpi_speaker


audio-on
wpctl status
wpctl set-volume 69 80%
alsamixer (digital)


curl -sSL https://github.com/skuligowski/raspi-hifi/archive/refs/heads/main.zip -o rasp-hifi.zip && unzip rasp-hifi.zip && cd raspi-hifi-main 
sudo curl -sSL https://raw.githubusercontent.com/skuligowski/raspi-hifi/refs/heads/main/setup.sh -o setup.sh | sh