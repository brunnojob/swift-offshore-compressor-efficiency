# swift-offshore-compressor-efficiency

Calculate ideal-gas compressor efficiency and flag thermodynamically inconsistent trend records.

```sh
swiftc Sources/main.swift -o app
./app --self-test
./app < examples/input.txt
```

Offline diagnostic CLI built with Foundation. Sample records are synthetic; deployment needs measured data and installation-specific acceptance limits.

MIT. Built by [brunnodev](https://brunnodev.store).
