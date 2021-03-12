# nephelaiio.growfs

[![Build Status](https://github.com/nephelaiio/ansible-role-growfs/workflows/CI/badge.svg)](https://github.com/nephelaiio/ansible-role-growfs/actions)
[![Ansible Galaxy](http://img.shields.io/badge/ansible--galaxy-nephelaiio.growfs.vim-blue.svg)](https://galaxy.ansible.com/nephelaiio/growfs/)

An opinionated [ansible role](https://galaxy.ansible.com/nephelaiio/growfs) to grow filesystems for linux systems

## Role Variables

Please refer to the [defaults file](/defaults/main.yml) for an up to date list of input parameters.

## Example Playbook

- hosts: servers
  roles:
     - role: nephelaiio.growfs

## Testing

Please make sure your environment has [docker](https://www.docker.com) installed in order to run role validation tests. Additional python dependencies are listed in the [requirements file](https://github.com/nephelaiio/ansible-role-requirements/blob/master/requirements.txt)

Role is tested against the following distributions (kvm guests):

  * Ubuntu Focal
  * Ubuntu Bionic
  * Ubuntu Xenial
  * CentOS 7

You can test the role directly from sources using command ` molecule test `

## License

This project is licensed under the terms of the [MIT License](/LICENSE)
