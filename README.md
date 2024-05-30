## localsend-cli

**localsend-cli** is a command line tool to send & receive data with other devices running [Localsend](https://localsend.org).


### Features

 - [x] Discover nearby peers
 - [x] Send text message to a peer
 - [ ] Send multiple text messages to a peer
 - [ ] Send text(s) to multiple peers
 - [ ] Receive data from peers
 - [ ] Configuration Options


### Usage

```bash
localsend-cli -h  # prints help message
localsend-cli send -text "hello world!"  # sends a text message to selected device
```

### Build

This would produce binary inside `bin` folder.

```bash
nimble build
```


### Install

This would build and install the binary in your machine.

```bash
nimble install
```
