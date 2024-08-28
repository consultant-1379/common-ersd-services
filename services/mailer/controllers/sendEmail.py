import sys, urllib, json, datetime, os, smtplib, re, argparse
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.image import MIMEImage

SMTP_SERVER = 'smtp.internal.ericsson.com'
FROM_EMAIL_ADDRESS = 'environment.management.tool@ericsson.com'
HOME_DIRECTORY = '/usr/src/app/'

class CommonErsdMailer():
    """
    Mailer functionality for sending emails from Common ERSD Services
    """

    def __init__(self, recipients, subject, cc=None):
        self.message = MIMEMultipart()
        self.message['From'] = FROM_EMAIL_ADDRESS
        self.parse_recipients(recipients)
        self.cc = ''
        self.message['Subject'] = subject
        self.server = smtplib.SMTP(SMTP_SERVER)

    def parse_recipients(self, recipients):
        """
        :param recipients: who we want to send the email to
        Functionaily to check the format of recipients and do formating as necessary.
        """
        if (',' in recipients):
            all_reciptients = recipients.split(",")
            self.recipients = all_reciptients
            self.message['To'] = ", ".join(all_reciptients)
        else:
            self.recipients =  eval('[\'' + recipients + '\']')
            self.message['To'] = recipients

    def get_html_body(self):
        """
        Read the HTML file to be used for the email.
        """
        html_file_body = open(HOME_DIRECTORY + 'emailBody.html', 'r')
        return html_file_body.read()

    def attach_logo(self):
        """
        Attach the logo to the email and set the content ID.
        """
        logo = open(HOME_DIRECTORY + 'controllers/ericsson_logo.png', 'rb')
        message_logo = MIMEImage(logo.read())
        logo.close()

        message_logo.add_header('Content-ID', '<ericssonLogo>')
        self.message.attach(message_logo)

    def attach_image(self):
        """
        Attach the image to the email and set the content ID.
        """
        image = open(HOME_DIRECTORY + 'controllers/this-is-fine.jpg', 'rb')
        message_image = MIMEImage(image.read())
        image.close()

        message_image.add_header('Content-ID', '<fine>')
        self.message.attach(message_image)

    def attach_html_body(self):
        """
        Attach the HTML which can be used as the body for the email.
        """
        body_as_html = MIMEText(self.get_html_body(), 'html')
        self.message.attach(body_as_html)

    def send_message(self):
        """
        Send the email.
        """
        text = self.message.as_string()
        formatted_cc =  eval('[\'' + self.cc + '\']')
        to_address = self.recipients + formatted_cc
        self.server.sendmail(FROM_EMAIL_ADDRESS, to_address, text)
        self.server.quit()

    def remove_file(self):
        """
        Remove the html file. Clean up for the docker container.
        """
        os.remove(HOME_DIRECTORY + 'emailBody.html')

def parseArgs():
    """
    Function used to parse the arguments passed in
    """
    parser = argparse.ArgumentParser()
    parser.add_argument('-s', '--subject',
    help="Subject for the email",
    required=True)
    parser.add_argument('-r', '--recipients',
    help="recipients we want to send email to",
    required=True)
    return parser.parse_args()

if __name__ == "__main__":
    parsed_args = parseArgs()
    mailer = CommonErsdMailer(parsed_args.recipients, parsed_args.subject)
    mailer.attach_html_body()
    mailer.attach_logo()
    mailer.attach_image()
    mailer.send_message()
    mailer.remove_file()
