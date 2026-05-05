# libp2p Mix Examples

Standalone Nim examples for running libp2p Ping over the Mix protocol and for
demonstrating a switch with multiple transports.

## Examples

This repository contains three runnable examples:

- `mix_ping_tcp.nim` - sends a Ping through a Mix overlay using TCP transport
  for the mix nodes and destination.
- `mix_ping_quic.nim` - sends a Ping through a Mix overlay using QUIC transport
  for the mix nodes and destination.
- `multiple_transports_example.nim` - creates libp2p switches that support both
  TCP and QUIC, then runs one Ping preferring QUIC and one Ping preferring TCP.

## Quick Start

Prerequisites:

- Nim 2.0 or newer
- Nimble
- Git

From a fresh clone:

```bash
nimble setup -l
nim c -r mix_ping_tcp.nim
```

`nimble setup -l` enables project-local dependency mode, installs dependencies
under `nimbledeps/`, and generates `nimble.paths` and `nimble.develop`.

Run the individual examples with:

```bash
nim c -r mix_ping_tcp.nim
nim c -r mix_ping_quic.nim
nim c -r multiple_transports_example.nim
```

The Mix examples start several local libp2p nodes, build a Mix overlay, and send
a Ping request through that overlay to a destination node. The multi-transport
example starts separate client switches for the QUIC-preferred and TCP-preferred
pings so that libp2p connection reuse does not hide which transport was selected.

## Local Files

The repository uses `config.nims` to keep Nim build output in the local
`nimcache/` directory and to include `nimble.paths` when it exists.

These files and directories are local artifacts and should not be committed:

- `nimbledeps/`
- `nimble.paths`
- `nimble.develop`
- `nimcache/`
- `mix_ping_tcp`
- `mix_ping_quic`
- `multiple_transports_example`

## Clean Rebuild

To verify the project can be rebuilt from committed files:

```bash
rm -rf nimbledeps nimble.paths nimble.develop nimcache \
  mix_ping_tcp mix_ping_quic multiple_transports_example
nimble setup -l
nim c -r mix_ping_tcp.nim
nim c -r mix_ping_quic.nim
nim c -r multiple_transports_example.nim
```

If `nimble setup -l` reports that it cannot determine the VCS revision, make at
least one Git commit first, then rerun the command.
