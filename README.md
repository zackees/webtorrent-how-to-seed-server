Webtorrent How To: Create a Seed-Server
=======================================

Want to know how to serve a video reliably over the internet using webtorrent? This is how you do it.
If you like this content, consider giving this repo a star.

# Step 1: Get a VPS on Digital Ocean

Get the cheapest one, which will have 10GB of storage ($7 for 25GB), which is plenty to start out with. Once you have this machine up and running, use the access console to ssh into the machine through the web browser (or ssh if you know how to configure your keys).

# Step 2: Install all dependencies to VPS

Run this to install the following dependencies on the VPS. Tested on Ubuntu 20.04LTS.

Copy and paste this into a terminal:
```bash
apt update
apt install python3 python3-pip npm nodejs -y
pip install magic-wormhole

# Installs webtorrent components
npm install -g node-pre-gyp webtorrent-cli webtorrent-hybrid
```

Make sure that you have python installed on your own computer (Windows/MacOS/Ubuntu), because we will use it later to upload the file.

# Step 3: Upload your content to the VPS

Make sure that you have python installed on both your VPS and your home computer.

Next prepare the content for serving, let's call it `movie.mp4`. We will use `magic-wormhole` on both server and local computer to transfer the file, since that's the easiest way I've found it to work.

#### Magic Wormhole to transfer the file

On your local machine install magic-wormhole: `pip install magic-wormhole`.

On the local machine, use this command
```bash
wormhole send movie.mp4
```
And it will return something like `wormhole receive waddle-coffee-pancake`, paste this exactly into the remote computer and the file will be uploaded to the server.

# Step 4: Run webtorrent-hybrid, which will act as the seeding server

Start seeding by using the following command:

`webtorrent-hybrid seed myfile --keep-seeding --port 80 -q`

And wait for the magnet uri to be printed. Save the magnet uri.

Now test this link by pasting it into [instant.io](https://instant.io) and verifying that the movie loads within 10 seconds.

Congrats! Now you have a magnet uri that will work (most) everywhere. However we aren't done yet. As soon as your close your SSH session your seeding process will also be killed. To make a service which will always be alive, go to the next step.

# Step 5: Using `pm2` to create an always on seeder service.

Creating a system service *normally* requires intermediate unix admin skills. Luckily this has all been made too easy with the excellent tool called `pm2`. So let's install it: `npm install -g pm2`

In the current VPS shell, make a new file: `nano ./app.js` and edit it so that it has the following:

```js
const { exec } = require('child_process')
//
// EDIT THIS
const FILE_PATH = "movie.mp4"
//
//
const CMD = `webtorrent-hybrid seed ${FILE_PATH} --keep-seeding --port 80 -q`
exec(CMD, (error, stdout, stderr) => {
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
```

Exit and save the file` in the nano editor. Now lets turn this into a service!

`pm2 start ./app.js` `pm2 save`

That's it! To check that the service is running you can do `pm2 ls` and check that there is an entry for app.js.

**Congrats!** You now have an always on seeding service. You can confirm this by issuing a restart command to your VPS and notice both the app.js process is running using `pm2 ls`.

# Step 6: An HTML/JS video player

Remember that magnet uri I told you to remember? You are going to use it here. Replace `magneturi` with yours.

```html
<html>

<style>
  video {
    width: 100%;
    height: 100%;
  }

</style>

<body>
  <section>
    <h1 id="info">Movie player loading....</h1>
    <div id="content"></div>
  </section>
</body>

<script src="https://cdn.jsdelivr.net/npm/webtorrent@latest/webtorrent.min.js"></script>
<script>
  const client = new WebTorrent()
  // get the current time
  const time = new Date().getTime()  // Used to print out load time.

  //
  // REPLACE THIS WITH YOUR MAGNET URI!!!!
  const magneturi = 'REPLACE THIS WITH YOUR MAGNET URI'
  //
  //

  const torrent = client.add(magneturi, () => {
    console.log('ON TORRENT STARTED')
  })

  console.log("created torrent")

  torrent.on('warning', console.warn)
  torrent.on('error', console.error)
  /*
  torrent.on('download', console.log)
  torrent.on('upload', console.log)
  */

  torrent.on('warning', (a) => { console.warn(`warning: ${a}`) })
  torrent.on('error', (a) => { console.error(`error: ${a}`) })
  //torrent.on('download', (a) => { console.log(`download: ${a}`) })
  //torrent.on('upload', (a) => { console.log(`upload: ${a}`) })


  torrent.on('ready', () => {
    document.getElementById("info").innerHTML = "Movie name: " + torrent.name
    console.log('Torrent loaded!')
    console.log('Torrent name:', torrent.name)
    console.log('Found at:', new Date().getTime() - time, " in the load")
    console.log(`Files:`)
    torrent.files.forEach(file => {
      console.log('- ' + file.name)
    })
    // Torrents can contain many files. Let's use the .mp4 file
    const file = torrent.files.find(file => file.name.endsWith('.mp4'))
    // Display the file by adding it to the DOM
    file.appendTo('body', { muted: true, autoplay: true })
  })
</script>

</html>
```

Now save and run this file on a webserver. You could just run `python -m http.server --port 80` and then open your web browser to `http://localhost` to preview.

# Next Steps

You could of course, create a multi-seeder tool that spawns one process per video and serve an entire library of content. This is apparently what Bitchute and PeerTube do.

Thanks to Feross for a great software stack.

Hopefuly he will be inspired to update the docs on how to run a seed server. It took me weeks to figure all this out and it seems like an important use case. Happy serving!
