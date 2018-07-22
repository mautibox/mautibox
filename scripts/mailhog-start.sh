#!/usr/bin/env bash
# Install and configure Mailhog to capture all outgoing mail.

# Install go.
cd /tmp
curl -O https://storage.googleapis.com/golang/go1.6.linux-amd64.tar.gz
tar xvf go1.6.linux-amd64.tar.gz
sudo mv /tmp/go /usr/local/bin
sudo chown -R root:root /usr/local/bin/go
sudo mkdir -p /work
export GOPATH=/work
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

# Install Mailhog
cd /tmp
wget https://github.com/mailhog/MailHog/releases/download/v0.2.1/MailHog_linux_amd64
sudo cp MailHog_linux_amd64 /usr/local/bin/mailhog
sudo chown -R root:root /usr/local/bin/mailhog
sudo chmod +x /usr/local/bin/mailhog

# Install mhsendmail for PHP to always use Mailhog.
# go get github.com/mailhog/mhsendmail
# sudo ln /work/bin/mhsendmail /usr/local/bin/mhsendmail
# sudo ln /work/bin/mhsendmail /usr/local/bin/sendmail
# sudo ln /work/bin/mhsendmail /usr/local/bin/mail

# Enable and run the Mailhog daemon.
systemctl enable mailhog.service
systemctl start mailhog.service

# Gracefully reload apache configuration.
sudo /etc/init.d/httpd graceful