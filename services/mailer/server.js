const express = require('express');
const bodyParser = require('body-parser');

const app = express();
const cors = require('cors');
const server = require('http').Server(app);

const mailerRoutes = require('./routes/mailer.routes');

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({
  extended: false,
}));

app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Access-Control-Allow-Headers, Origin, X-Requested-With, Content-Type, Accept, Access-Control-Request-Method, Access-Control-Request-Headers');
  res.header('Access-Control-Allow-Methods', 'DELETE, HEAD, GET, POST, PUT, OPTIONS');
  next();
});
app.use(cors());

// Set our api routes
app.use('/mailer', mailerRoutes);

const port = 3001;
app.set('port', port);

if (!module.parent) {
  server.listen(port, () => console.log(`API running on localhost:${port}`));
}

module.exports = server;
