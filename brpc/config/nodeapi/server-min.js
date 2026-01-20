//// Automate REST API ////
// by Ben Provenzano III //

const { query, validationResult } = require('express-validator');
const express = require('express');
const json = require('express');
const app = express();

const httpPort = 3000;
const regex = /^[A-Za-z0-9_.#%@&-]*$/;

app.use(json());

// run shell command
app.get('/api', [
    query('arg').notEmpty().withMessage('[arg] parameter cannot be empty')
               .matches(regex).withMessage('invalid [arg] parameter'),
    query('var').matches(regex).withMessage('invalid [var] parameter')
  ], (req, res) => {
  const arg1 = `${req.query.arg} `;
  const arg2 = `${req.query.var} `;
  try {
    // collect any validation errors
    const errs = validationResult(req);
    if (!errs.isEmpty()) { // return 400 on error
      return res.status(400).json({ errors: errs.array() });
    }
    const { exec } = require('child_process');
    const cmd = '/usr/bin/sudo /opt/system/webapi.sh ' + arg1 + arg2;
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

app.listen(httpPort, '127.0.0.1', () => {
  console.log(`Automate API running on port ${httpPort}`);
});

