# Architecture

- `core/`: shared application logic and version information.
- `hardware/`: hardware discovery interfaces.
- `platform/`: operating-system-specific implementations.
- `tests/`: automated tests.

The Linux backend currently reads standard, read-only system interfaces.
Future hardware controls must validate capabilities and report unsupported
operations rather than assuming every laptop supports them.
