# Install this with:
# curl -sL https://raw.githubusercontent.com/zackees/webtorrent-how-to-seed-server/main/install_ubuntu22.sh | sudo -E bash -

apt update
apt install python3 python3-pip npm nodejs -y
pip install magic-wormhole

# Installs webtorrent components
npm install -g node-pre-gyp webtorrent-cli webtorrent-hybrid

