OSDEV
=====
Higher-half x64 OS kernel stub in ELF64 format, loaded from exFAT.

This is a **hobby** project. The only goal is to learn how an OS' internals (including the C runtime) work (in detail). The most obvious, and probably non optimal, way of doing things is always used.

It works in QEMU or VirtualBox.

Boot sector uses GNU as with AT&T syntax (cause I wanted to try it). Same goes for second stage. Boot sector in the drive's Master Boot Record loads the second stage form the second sector of the drive. Second stage loads KERNEL.BIN from the root directory of the active exFAT partition. It should handle non-contiguous clusters.

Second stage goes into Protected Mode, then Long Mode and sets up a higher-half x64 kernel in ELF64 format, with the first 2Mb of real memory identity mapped to the first 2Mb of the higher-half of virtual memory.

The rest is written in C, with some inline assembly. There are interrupt handlers for the timer, the keyboard and General Protection Faults.

Project file structure
---------------------
* **build/** - all intermediary, object and binary files end up here
* **include/** - header files go here
* **src/** - assembly and C files go here
* **tryouts/** - source code for trying out stuff before using it in the actual project
* **vbox/** - files for testing with VirtualBox
* **bootsect.gdb** - GNU debugger script file
* **create_vhd.ps1** - create a 10Mb VHD file with a single bootable exFAT formatted partition
* **kernel_to_vhd.ps1** - write the kernel to the root of the exFAT partition, along with other files, so it ends up split between non-contiguous clusters
* **kernel.ld** - GNU ld linker script
* **Makefile** - GNU Makefile to build the project
* ... various other files

Requirements
------------
* windows
* msys2 - x86_64, with following packages
  * mingw-w64-i686-toolchain
  * mingw-w64-x86_64-toolchain
* **x86_64 ELF GCC cross-compiler** that you have to build for yourself (see https://wiki.osdev.org/GCC_Cross-Compiler)
* [dd for windows](http://www.chrysocome.net/dd)
* qemu
* _VirtualBox, optional_
* _VSCode & C/C++ extension & Native Debug extension, optional_

Running with QEMU
----------------
* ```make```
* ```qemu-system-x86_64.exe -drive file=build/drive.vhd,format=vpc```

Running with VirtualBox
----------------------
* ```make vbox```
* ```VBoxManage startvm bootsect```

Debugging with GDB & QEMU
------------------------
* ```make```
* ```gdb -x bootsect.gdb```

Debugging with VSCode & QEMU
---------------------------
The following tasks need to be in your ```tasks.json``` file : 

    {
      "label": "qemu kernel.c",
      "type": "shell",
      "command": "qemu-system-x86_64w.exe",
      "args": [
          "-pidfile",
          "qemu_kernel_c.pid",
          "-s",
          "-S",
          "-drive",
          "file=build/drive.vhd,format=vpc"
      ],
      "dependsOn": "build kernel.c"
    },
    {
        "label": "kill qemu kernel.c",
        "type": "shell",
        "command": "powershell",
        "args": [
            "Stop-Process -Id $(Get-Content qemu_kernel_c.pid)"
        ]
    }

The following configuration needs to be in your ```launch.json``` file :

    {
        "type": "gdb",
        "request": "attach",
        "name": "gdb kernel.c",
        "executable": "./build/kernel.bin",
        "target": ":1234",
        "remote": true,
        "cwd": "${workspaceRoot}",
        "valuesFormatting": "parseText",
        "preLaunchTask": "qemu kernel.c",
        "postDebugTask": "kill qemu kernel.c"
    }
