This will be the base image from which laravel deployment images will be build.
It is build with HashiCorp packer tool.

Ref: https://www.packer.io/intro/


example:
packer build base-image.json

Note:
Account for docker hub is created and the initial image is builded and pushed there, credentials will be provided as part of the architecture file :)