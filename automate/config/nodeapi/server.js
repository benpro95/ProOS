//// Automate REST API ////
// by Ben Provenzano III //

const { readFileSync, writeFile } = require('fs');
const { query, validationResult } = require('express-validator');
const express = require('express');
const json = require('express');
const app = express();
const os = require('os');
const hostname = os.hostname();

const httpPort = 3000;
const rwPath = '/var/www/html/ram';
const maxReadBytes = 64000;
const regex = /^[A-Za-z0-9_.#%@&-]*$/;

app.use(json());

// run shell command
app.get('/api', [
    query('action').notEmpty().withMessage('[action] parameter cannot be empty')
               .matches(regex).withMessage('invalid [action] parameter'),
    query('arg').matches(regex).withMessage('invalid [arg] parameter'),
    query('var').matches(regex).withMessage('invalid [var] parameter')
  ], (req, res) => {
  const action = `${req.query.action} `;
  const arg1 = `${req.query.arg} `;
  const arg2 = `${req.query.var} `;
  try {
    // collect any validation errors
    const errs = validationResult(req);
    if (!errs.isEmpty()) { // return 400 on error
      return res.status(400).json({ errors: errs.array() });
    }
    const { exec } = require('child_process');
    const cmd = '/usr/bin/sudo /opt/rpi/' + action + arg1 + arg2;
    exec(cmd, (err, stdout, stderr) => {
      if (err) {
        res.status(500).json(`command returned an error: ${stderr} ${stdout}`);
      } else {
        res.status(200).json(`${stdout}`);
      }
    });
  } catch (err) {
    res.status(500).json(`internal server error: ${err}`);
  }
});

// read file contents
app.get('/api/read', [
  query('file').notEmpty().withMessage('[file] parameter cannot be empty')
           .matches(regex).withMessage('invalid [file] parameter')
  ], (req, res) => {
  const filename = req.query.file;
  try {
    // collect any validation errors
    const errs = validationResult(req);
    if (!errs.isEmpty()) { // return 400 on error
      return res.status(400).json({ errors: errs.array() });
    }
    const file = readFileSync(`${rwPath}/${filename}.txt`, 'utf8');
    res.status(200).json(file.slice(-maxReadBytes));
  } catch (err) {
    res.status(500).json(`internal server error: ${err}`);
  }
});

// write file contents
app.post('/api/write', [
  query('file').notEmpty().withMessage('[file] parameter cannot be empty')
           .matches(regex).withMessage('invalid [file] parameter')
  ], (req, res) => {
  const filename = req.query.file;
  try {
    // collect any validation errors
    const errs = validationResult(req);
    if (!errs.isEmpty()) { // return 400 on error
      return res.status(400).json({ errors: errs.array() });
    }
    var body = '';
    path = `${rwPath}/${filename}.txt`;
    req.on('data', (data) => {
      body += data;
    });
    req.on('end', () => {
      writeFile(path, body, () => {
        res.status(200).end();
      });
    });
  } catch (err) {
    res.status(500).json(`internal server error: ${err}`);
  }
});

app.listen(httpPort, '127.0.0.1', () => {
  console.log(`${hostname} API running on port ${httpPort}`);
});

