#!/bin/bash
apt-get -y update
apt-get -y install wireguard
apt-get -y install apache2
apt-get -y install awscli

# Generate priv and pub keys
wg genkey > priv
sudo chmod 700 priv
cat priv | wg pubkey > pub
sed -i "s|privkeyhere|`cat priv`|" wg0.conf
# Config firewall
ufw allow 52888/udp
ufw allow 22/tcp
ufw allow 53/udp
ufw allow 80/tcp
ufw disable
echo 'y' | sudo ufw enable
# Allow packet forwarding
sed -i "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/" /etc/sysctl.conf
sysctl -p
# Enable wg service
systemctl enable wg-quick@wg0.service
systemctl start wg-quick@wg0.service
# Create webpage with public key and start apache
{
  echo '<html><body><h2>Server Public Key: '
  echo `cat pub`
  echo '</h2></body></html>'
} > /var/www/html/index.html
systemctl start apache2.service
systemctl enable apache2.service
aws ssm put-parameter --name '/wg0/pubkey' --type String --value `cat pub` --overwrite --region $AWSREG