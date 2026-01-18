const express = require('express');
const fs = require('fs');
const app = express();
const httpPort = process.env.PORT || 3000;
const rwPath = "/var/www/html/ram";
const maxReadBytes = 30000;

//$regex = '/^[A-Za-z0-9_.#%@&-]*$/';

app.use(express.json());

app.get('/api', (req, res) => {
  const action = `${req.query.action} `;
  const arg1 = `${req.query.arg} `;
  const arg2 = `${req.query.var} `;
  // run shell command
  const { exec } = require('child_process');
  exec('/usr/bin/sudo /opt/rpi/' + action + arg1 + arg2, (err, stdout, stderr) => {
    if (err) {
      res.json(`error: ${stderr} ${stdout}`);
    } else {
      res.json(`${stdout}`);
    }
  });
});

app.get('/api/read', (req, res) => {
  const filename = req.query.file;
  try {
    // read file contents
    const file = fs.readFileSync(`${rwPath}/${filename}.txt`, 'utf8');
    const lastLines = file.slice(-maxReadBytes);
    res.json(lastLines);
  } catch (err) {
    res.json(`error reading: ${filename}`);
  }
});

app.post('/api/write', (req, res) => {
  const filename = req.query.file;
  var body = '';
  // write file contents
  filePath = `${rwPath}/${filename}.txt`;
  req.on('data', (data) => {
    body += data;
  });
  req.on('end', () => {
    fs.appendFile(filePath, body, () => {
      res.end();
    });
  });
});

app.listen(httpPort, '127.0.0.1', () => {
  console.log(`Automate API running on port ${httpPort}`);
});

