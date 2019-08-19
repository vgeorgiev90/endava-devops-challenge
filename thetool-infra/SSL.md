# Let's Encrypt integration

1. play is added for automatic lets encrypt certificate generation.
2. If generation fails generic certificate is placed so nginx can work,  which must be changed.
    *  Place your certificates in /etc/thetool-$ENV/certs/live/$DOMAIN/ with names: cert.pem and privkey.pem
    *  Restart webapp container: docker restart $ENV-webapp


NOTE: For letsencrypt certificate to be issued add existing domain with A record pointed to the public IP address of the webapp machine.
