## Building images.

For image building the management script can be used.
The only thing to keep in mind is the name format for the image-build sub command.

Example:
./manage.sh image-build webapp-v1

In the script logick the following is done.
The name provided is splited in two parts , with "-" as separator
First part is used to identify the packer file from which the image will be build ,
the second part is used as the image tag(So please avoid more than one dash as the tagged image name will be incomplete). 


Some examples:
Standard images and names - image-build webapp-app_v1, image-build daemons-d_v1

Different branch builds - image-build webapp-app_development_v1 , image-build daemons-d_development_v1, image-build webapp-app_feature_custom_database_v1 etc..

The images will tagged and pushed to the repository as follows.

fiftysaas/thetool-app:app_v1
fiftysaas/thetool-app:d_v1
fiftysaas/thetool-app:app_development_v1
fiftysaas/thetool-app:d_development_v1
fiftysaas/thetool-app:app_feature_custom_database_v1


