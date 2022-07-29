# Install this with:
# curl -sL https://raw.githubusercontent.com/zackees/webtorrent-how-to-seed-server/main/install_ubuntu22.sh | sudo -E bash -

apt update
apt install python3 python3-pip npm nodejs -y
pip install magic-wormhole

# Installs webtorrent components
npm install -g node-pre-gyp webtorrent-cli webtorrent-hybrid pm2

cat > seeder.js <<'_EOF'
const { exec } = require('child_process')
const FILE1 = "file.mp4"
const FILES = [
  FILE1
]

FILES.forEach(file => {
  const cmd = `webtorrent-hybrid seed ${file} --keep-seeding --port 80 -q > ${file}.magnet`
  console.log(`Generating magnet for ${file}`)
  exec(cmd, (error, stdout, stderr) => {
    console.log(`Finished ${file}`)
    if (error) {
      console.error("error", error.message)
      return;
    }
    if (stderr) {
      console.error(stderr)
    }
    if (stdout) {
      console.log(stdout)
    }
  })
})
_EOF




