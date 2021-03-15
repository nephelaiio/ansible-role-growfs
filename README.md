# nephelaiio.growfs

[![Build Status](https://github.com/nephelaiio/ansible-role-growfs/workflows/ci/badge.svg)](https://github.com/nephelaiio/ansible-role-growfs/actions)
[![Ansible Galaxy](http://img.shields.io/badge/ansible--galaxy-nephelaiio.growfs.vim-blue.svg)](https://galaxy.ansible.com/nephelaiio/growfs/)

An opinionated [ansible role](https://galaxy.ansible.com/nephelaiio/growfs) to grow filesystems for linux systems

## Use case
The main use case for the role is to automatically grow partitions/filesystems on systems installed using [nephelaiio.centos_installer](https://galaxy.ansible.com/nephelaiio/centos_installer) and [nephelaiio.ubuntu_installer](https://galaxy.ansible.com/nephelaiio/ubuntu_installer)

## Logic

The role will implement the following disk management logic when applied to a target system:
For non-lvm disks:
* Expand last partition when containig device has over 5% available unpartitioned space
* Grow mounted partition filesystems when applicable

For lvm with emtpy disks:
* Grow pvs when applicable
* Partition empty disks and assign device to lvm volume group
* Grow target lvm logical volume
* Optionally create and mount a new lvm logical volume

The role will fail when any of the following conditions are found
* A disk device filter (regex) is not defined
* Volume group is not unique
* Logical volume is not unique and an explicit selection has not been made

The role will exit as a no-op in the following cases:
* No LVM is present and a new disk is found

## Role Variables

Please refer to the [defaults file](/defaults/main.yml) for an up to date list of input parameters.

## Example Playbook

```
- hosts: servers
  roles:
     - role: nephelaiio.growfs
```

## Testing

Please make sure your environment has [docker](https://www.docker.com) installed in order to run role validation tests. Additional python dependencies are listed in the [requirements file](https://github.com/nephelaiio/ansible-role-requirements/blob/master/requirements.txt)

Role is tested against the following distributions (kvm guests):

  * Ubuntu Focal
  * CentOS 7

You can test the role directly from sources using command ` molecule test `

## License

This project is licensed under the terms of the [MIT License](/LICENSE)
