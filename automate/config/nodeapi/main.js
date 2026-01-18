// Automate Backend API //

const express = require('express');
const fs = require('fs');
const app = express();
const httpPort = process.env.PORT || 3000;
const rwPath = "/var/www/html/ram";
const maxReadBytes = 30000;

//$regex = '/^[A-Za-z0-9_.#%@&-]*$/';

app.use(express.json());

// run shell command
app.get('/api', (req, res) => {
  const action = `${req.query.action} `;
  const arg1 = `${req.query.arg} `;
  const arg2 = `${req.query.var} `;
  try {
    const { exec } = require('child_process');
    exec('/usr/bin/sudo /opt/rpi/' + action + arg1 + arg2, (err, stdout, stderr) => {
      if (err) {
        res.json(`error: ${stderr} ${stdout}`);
      } else {
        res.json(`${stdout}`);
      }
    });
  } catch (err) {
    res.json(`error running: ${action}`);
  }
});

// read file contents
app.get('/api/read', (req, res) => {
  const filename = req.query.file;
  try {
    const file = fs.readFileSync(`${rwPath}/${filename}.txt`, 'utf8');
    const lastLines = file.slice(-maxReadBytes);
    res.json(lastLines);
  } catch (err) {
    res.json(`error reading: ${filename}`);
  }
});

// write file contents
app.post('/api/write', (req, res) => {
  const filename = req.query.file;
  try {
    var body = '';
    filePath = `${rwPath}/${filename}.txt`;
    req.on('data', (data) => {
      body += data;
    });
    req.on('end', () => {
      fs.writeFile(filePath, body, () => {
        res.end();
      });
    });
  } catch (err) {
    res.json(`error writing: ${filename}`);
  }
});

app.listen(httpPort, '127.0.0.1', () => {
  console.log(`Automate API running on port ${httpPort}`);
});

