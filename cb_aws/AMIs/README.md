Readme
---

Use this repo to build images and tests that they comply to the security specs.

Dependencies required:
 - [Packer](https://www.packer.io/) 
 - [InSpec](https://community.chef.io/products/chef-inspec/)
 - [Ansible](https://docs.ansible.com/ansible/latest/index.html)


Security Compliance tests:
 - [dev-sec/linux-baseline](https://github.com/dev-sec/linux-baseline)
 - [dev-sec/ssh-baseline](https://github.com/dev-sec/ssh-baseline)


Usage
---
Make sure you setup your amazon credentials according to their defaults. That way packer can use it to run and generate images.


```
$ cd generic
$ packer build ami.json
```

Workflow (Packer)
---
1. Provision new AWS EC2 instance
2. Run hardening playbooks based on [dev-sec/ansible-os-hardening](https://github.com/dev-sec/ansible-os-hardening)
3. Run provisioning playbooks depending on the roles assigned
4. Use Chef's InSpec to perform security testing, if all tests pass commit the instance to AWS AMI


---

Notes: 

- Security tests for each machine can be found in specs directory
- Use shared/scripts/imageBuildServerPrepare.sh to setup dependencies for the localhost(created for ubuntu 20 workstation).
- Every playbook for a image is located in shared/ 

```
generic.yml
- hosts: all
  become: yes
  roles:
  - os_hardening
  - ssh_hardening
  - sd_monitoring
  - generic
  - ossec_agent
```

- Directory shared/roles holds all ansible plays(grouped in roles) for security testing and software provisioning.

