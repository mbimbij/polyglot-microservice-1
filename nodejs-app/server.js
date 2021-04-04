'use strict';

const express = require('express');
const { v4: uuidv4 } = require('uuid');

// Constants
const PORT = 8080;
const HOST = '0.0.0.0';
const UUID = uuidv4();

// App
const app = express();
app.get('/', (req, res) => {
  res.send('Hello nodeJS - v3 - '+UUID);
});

app.listen(PORT, HOST);
console.log(`Running on http://${HOST}:${PORT}`);
