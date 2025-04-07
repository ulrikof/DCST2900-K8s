For a VM to be live-migratable, it needs to fulfill some certain requirements:

- If it uses a dataVolume, that dataVolume needs to have the following access:

  ```yaml
  dataVolumeTemplates:
    spec:
      storage:
        accessModes:
          - ReadWriteMany
  ```

  This is since, for a brief period, there exists two virtual machine instances that need to mount on the same persistent volume. Generally, the default access mode is ReadWriteOnce, which will not work.

- The type of network interface might prevent live-migration. Masquerade is the often the default and most common setting, and this works. On the other side, for instance bridge mode, does not work, and cannot be used with live-migration. In its simplest form, it can be configured like this:

  ```yaml
  spec:
  template:
      spec:
      domain:
          devices:
          interfaces:
              - name: default
              masquerade: {}
  ```

An example VM file that works with live migration can be found under ./vm.yaml.
