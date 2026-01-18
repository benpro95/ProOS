const express = require('express');
const fs = require('fs');
const app = express();
const PORT = process.env.PORT || 3000;

//$regex = '/^[A-Za-z0-9_.#%@&-]*$/';

app.use(express.json());

app.get('/api', (req, res) => {
  // read individual parameters
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
  // read individual parameters
  const filename = req.query.file;
  try {
    const file = fs.readFileSync(`/var/www/html/ram/${filename}.txt`, 'utf8');
    res.json(file);
  } catch (err) {
    res.json(`error reading: ${filename}`);
  }
});

app.listen(PORT, '127.0.0.1', () => {
  console.log(`Automate API running on port ${PORT}`);
});

