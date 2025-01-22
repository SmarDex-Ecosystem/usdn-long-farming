# Changelog

## [1.0.0](https://github.com/SmarDex-Ecosystem/usdn-long-farming/compare/v0.2.0...v1.0.0) (2025-01-22)


### Features

* deploy token on mainnet ([#34](https://github.com/SmarDex-Ecosystem/usdn-long-farming/issues/34)) ([7887b29](https://github.com/SmarDex-Ecosystem/usdn-long-farming/commit/7887b29041ec7ae5a9b08a93483e2837d276e910))


### Miscellaneous Chores

* contracts addresses ([#36](https://github.com/SmarDex-Ecosystem/usdn-long-farming/issues/36)) ([04aa746](https://github.com/SmarDex-Ecosystem/usdn-long-farming/commit/04aa746dc7a09533ecb92984a398e2ae1c974c2d))

## [0.2.0](https://github.com/SmarDex-Ecosystem/usdn-long-farming/compare/v0.1.0...v0.2.0) (2025-01-15)


### ⚠ BREAKING CHANGES

* **slash:** The `burnedTokens` attribute of the `Slash` event has been renamed to `ownerRewards`

### Features

* **slash:** send slashed tokens to position owner instead of dead address ([#27](https://github.com/SmarDex-Ecosystem/usdn-long-farming/issues/27)) ([511f351](https://github.com/SmarDex-Ecosystem/usdn-long-farming/commit/511f351578b9de065df1f950ef726e72e11fe3b9))


### Bug Fixes

* follow cei ([#29](https://github.com/SmarDex-Ecosystem/usdn-long-farming/issues/29)) ([2050627](https://github.com/SmarDex-Ecosystem/usdn-long-farming/commit/2050627b97678aa690fd6e6bcba0445ba54f29f6))


### Miscellaneous Chores

* update flake and trufflehog ([#23](https://github.com/SmarDex-Ecosystem/usdn-long-farming/issues/23)) ([1a8cf6e](https://github.com/SmarDex-Ecosystem/usdn-long-farming/commit/1a8cf6e5ff3900386ee6b7aa20993bd00f7d4dd8))

## [0.1.0](https://github.com/SmarDex-Ecosystem/usdn-long-farming/compare/v0.0.1...v0.1.0) (2025-01-06)


### ⚠ BREAKING CHANGES

* staking to farming ([#7](https://github.com/SmarDex-Ecosystem/usdn-long-farming/issues/7))

### Features

* add reentrancyGuard and fix slither errors ([#17](https://github.com/SmarDex-Ecosystem/usdn-long-farming/issues/17)) ([fc2c46c](https://github.com/SmarDex-Ecosystem/usdn-long-farming/commit/fc2c46c9c24db1788f8dedbd076fee830b6217a7))
* add withdraw ([#16](https://github.com/SmarDex-Ecosystem/usdn-long-farming/issues/16)) ([841909f](https://github.com/SmarDex-Ecosystem/usdn-long-farming/commit/841909fe827fe2d8a82e113ab4fe09a983c4da13))
* boilerplate ([#4](https://github.com/SmarDex-Ecosystem/usdn-long-farming/issues/4)) ([4317ca7](https://github.com/SmarDex-Ecosystem/usdn-long-farming/commit/4317ca7fcd35d6dad025b1db8c6eba70144e9144))
* change getPositionInfo params ([#21](https://github.com/SmarDex-Ecosystem/usdn-long-farming/issues/21)) ([13c2b23](https://github.com/SmarDex-Ecosystem/usdn-long-farming/commit/13c2b2350d59f2ac9bd60c804d8cf7e0d6b13161))
* **deployment:** tenderly v0.1.0 ([#22](https://github.com/SmarDex-Ecosystem/usdn-long-farming/issues/22)) ([0e4e23c](https://github.com/SmarDex-Ecosystem/usdn-long-farming/commit/0e4e23ccdfd11abee1e5bb8912cdcda4bb0f74f4))
* deposit ([#5](https://github.com/SmarDex-Ecosystem/usdn-long-farming/issues/5)) ([d54e037](https://github.com/SmarDex-Ecosystem/usdn-long-farming/commit/d54e037a7b46e26d76e1ab73626c8736d33bd099))
* deposit via USDN protocol `transferPositionOwnership` ([#14](https://github.com/SmarDex-Ecosystem/usdn-long-farming/issues/14)) ([ee7e685](https://github.com/SmarDex-Ecosystem/usdn-long-farming/commit/ee7e685b1f966a4f5aa006779181a37bbb1e95ed))
* harvest and notify liquidations ([#6](https://github.com/SmarDex-Ecosystem/usdn-long-farming/issues/6)) ([dbdd180](https://github.com/SmarDex-Ecosystem/usdn-long-farming/commit/dbdd1806cb8e2447c5257874d3ec1eb85b399604))
* pendingRewards ([#15](https://github.com/SmarDex-Ecosystem/usdn-long-farming/issues/15)) ([cc5f2bb](https://github.com/SmarDex-Ecosystem/usdn-long-farming/commit/cc5f2bb5d5655619e0fd6ddcd59afb281dc8e287))
* **script:** update deployment script ([#18](https://github.com/SmarDex-Ecosystem/usdn-long-farming/issues/18)) ([44fa649](https://github.com/SmarDex-Ecosystem/usdn-long-farming/commit/44fa6490f849c297080e2205c3f11ecf3a01a1f8))


### Miscellaneous Chores

* package.json ([#2](https://github.com/SmarDex-Ecosystem/usdn-long-farming/issues/2)) ([928c4a6](https://github.com/SmarDex-Ecosystem/usdn-long-farming/commit/928c4a67af7b2a237cbb647e0047ed1e070aef50))
* update npm deps ([#12](https://github.com/SmarDex-Ecosystem/usdn-long-farming/issues/12)) ([ce86406](https://github.com/SmarDex-Ecosystem/usdn-long-farming/commit/ce8640627a4b254c03fc5459de8d6e57e4ee339b))


### Code Refactoring

* files and folders ([#3](https://github.com/SmarDex-Ecosystem/usdn-long-farming/issues/3)) ([f1a858c](https://github.com/SmarDex-Ecosystem/usdn-long-farming/commit/f1a858caeb2d2224931e3b008f94cfd4a1809c5b))
* staking to farming ([#7](https://github.com/SmarDex-Ecosystem/usdn-long-farming/issues/7)) ([774e01f](https://github.com/SmarDex-Ecosystem/usdn-long-farming/commit/774e01fc7160c78fb8999ba48e9a5b4c5c3b8815))


### Build System

* change namespace of dependencies ([#19](https://github.com/SmarDex-Ecosystem/usdn-long-farming/issues/19)) ([0754e9d](https://github.com/SmarDex-Ecosystem/usdn-long-farming/commit/0754e9d91ccf9c02ce328f1023463a1beb406b45))
