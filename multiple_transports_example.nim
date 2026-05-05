# SPDX-License-Identifier: MIT

## Multiple Transports Example
## 
## This example demonstrates using multiple transport protocols (TCP and QUIC) 
## with libp2p.
## It creates a switch that listens on both TCP and QUIC addresses,
## then performs ping operations preferring each transport protocol to
## show how to use multiple transports in a libp2p application.

{.used.}

import chronos
import std/[sequtils, strutils]
import libp2p/[
  builders,
  crypto/crypto,
  multiaddress,
  peerid,
  protocols/ping,
  switch,
]

proc newTcpQuicSwitch*(
    privKey: Opt[PrivateKey] = Opt.none(PrivateKey),
    rng: ref HmacDrbgContext = newRng()
): Switch =
  ## A switch that listens on TCP and QUIC addresses.
  let addrs = @[
    MultiAddress.init("/ip4/0.0.0.0/udp/0/quic-v1").tryGet(),
    MultiAddress.init("/ip4/0.0.0.0/tcp/0").tryGet(),
  ]

  var builder = SwitchBuilder
    .new()
    .withRng(rng)
    .withAddresses(addrs)
    .withNoise()
    .withMplex()
    .withQuicTransport()
    .withTcpTransport()

  privKey.withValue(key):
    builder = builder.withPrivateKey(key)

  builder.build()

proc quicPreferred*(addrs: seq[MultiAddress]): seq[MultiAddress] =
  ## Dial order is address order, so put QUIC addresses before fallback transports.
  addrs.filterIt("/quic-v1" in $it) &
    addrs.filterIt("/quic-v1" notin $it)

proc tcpPreferred*(addrs: seq[MultiAddress]): seq[MultiAddress] =
  ## Dial order is address order, so put TCP addresses before QUIC fallback.
  addrs.filterIt("/quic-v1" notin $it) &
    addrs.filterIt("/quic-v1" in $it)

proc connectPreferringQuic*(
    localSwitch: Switch, remotePeerId: PeerId, remoteAddrs: seq[MultiAddress]
) {.async: (raises: [CancelledError, DialFailedError]).} =
  await localSwitch.connect(remotePeerId, quicPreferred(remoteAddrs))

proc pingPreferringQuic*(
    localSwitch: Switch,
    pingProtocol: Ping,
    remotePeerId: PeerId,
    remoteAddrs: seq[MultiAddress],
): Future[Duration] {.
    async: (raises: [CancelledError, DialFailedError, LPStreamError,
      WrongPingAckError])
.} =
  let conn = await localSwitch.dial(remotePeerId, quicPreferred(remoteAddrs),
  PingCodec)
  defer:
    await conn.close()

  await pingProtocol.ping(conn)

proc pingPreferringTcp*(
    localSwitch: Switch,
    pingProtocol: Ping,
    remotePeerId: PeerId,
    remoteAddrs: seq[MultiAddress],
): Future[Duration] {.
    async: (raises: [CancelledError, DialFailedError, LPStreamError,
      WrongPingAckError])
.} =
  let conn = await localSwitch.dial(remotePeerId, tcpPreferred(remoteAddrs),
    PingCodec)
  defer:
    await conn.close()

  await pingProtocol.ping(conn)

when isMainModule:
  proc main() {.async: (raises: [CancelledError, LPError]).} =
    let rng = newRng()
    let pingProtocol = Ping.new(rng = rng)
    let
      quicClient = newTcpQuicSwitch(rng = rng)
      tcpClient = newTcpQuicSwitch(rng = rng)
      b = newTcpQuicSwitch(rng = rng)

    b.mount(pingProtocol)

    await quicClient.start()
    await tcpClient.start()
    await b.start()
    defer:
      await quicClient.stop()
      await tcpClient.stop()
      await b.stop()

    let quicRtt = await quicClient.pingPreferringQuic(
      pingProtocol, b.peerInfo.peerId, b.peerInfo.addrs
    )
    echo "quic ping: ", quicRtt

    let tcpRtt = await tcpClient.pingPreferringTcp(
      pingProtocol, b.peerInfo.peerId, b.peerInfo.addrs
    )
    echo "tcp ping: ", tcpRtt

  waitFor main()
