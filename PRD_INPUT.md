= Input to PRD.md

*Name*

embedded-linux-demonstrator

*Purpose*

- show yocto build
- show software update with U-Boot
- show secure boot

*Requirements*

1. A linux build image for Raspi-4 should be produced
2. Raspi-4 should use the 7' display
3. build should work also for QEMU ARM64 emulator
4. the user should be able to set an external application referenced by a git tag
5. if the user does not set this external application git tag then just the provided sample application about system info and update should be used
6. breakpoints on U-Boot should work
7. the project shall support Docker on Mac and WSL