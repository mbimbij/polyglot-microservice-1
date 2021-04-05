'use strict';

// libraries
const express = require('express');

// "modules" / "packages"
const core = require('./core.js');

// Constants
const PORT = 8080;
const HOST = '0.0.0.0';

// App
const app = express();
app.get('/', (req, res) => {
  res.send(core.handleRequest());
});

app.listen(PORT, HOST);
console.log(`Running on http://${HOST}:${PORT}`);
