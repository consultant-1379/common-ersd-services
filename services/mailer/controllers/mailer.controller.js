const { exec } = require('child_process');
const fileSystem = require('fs');
const alertTriggered = require('../emails/alertTriggered');

/**
 * mailer.controller.js
 *
 * @description :: Server-side logic for sending emails.
 */
module.exports = {

  send(req, res) {
    let emailSubject = 'WARNING: A Grafana Alert Has Been Triggered';
    const emailId = 'BumbleBee.ENM@tcs.com';
    if (process.env.NODE_ENV === 'DEV') {
      emailSubject = `${process.env.NODE_ENV} ENV: ${emailSubject}`;
    }
    const emailBody = alertTriggered.alertTriggeredEmail(req.body);

    fileSystem.writeFile('./emailBody.html', emailBody, (err) => {
      if (err) console.log('ERROR: writing html');
      console.log('File Saved');
    });

    exec(`python ./controllers/sendEmail.py -s "${emailSubject}" -r "${emailId}"`, (err, stdout, stderr) => {
      if (err) {
        console.log('ERROR: calling python file sendEmail.py');
        console.log(`stderr: ${stderr}`);
      }
      console.log(`stdout: ${stdout}`);
    });

    return res.status(200).json();
  },
};
