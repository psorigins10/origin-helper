# ORIGIN Helper Roadmap

## Foundation
- [x] C++20 and CMake project
- [x] Basic Linux system and hardware discovery
- [x] Initial test target

## Hardware management
- [ ] Detect CPU and GPU models reliably
- [ ] Report battery status and charging information
- [ ] Investigate supported ASUS platform interfaces
- [ ] Add safe, validated battery charge-limit control where supported
- [ ] Add performance profiles where supported
- [ ] Add fan and GPU controls only after hardware verification

## Quality
- [ ] Expand automated tests
- [ ] Add structured logging and configuration
- [ ] Add compatibility documentation
- [ ] Add packaging and installation instructions
- [ ] Design a graphical interface

## Long-term
- [ ] Keep platform-independent logic separate from Linux backends
- [ ] Investigate an ORIGIN OS backend when its hardware interfaces exist
