## localsend-cli

**localsend-cli** is a command line tool to send & receive data with other devices running [Localsend](https://localsend.org).


### Features

 - [x] Discover nearby peers
 - [x] Send text message to a peer
 - [ ] Send multiple text messages to a peer
 - [ ] Send text(s) to multiple peers
 - [ ] Receive data from peers
 - [x] Configuration Options


### Usage

```bash
localsend-cli -h  # prints help message
localsend-cli send -text "hello world!"  # sends a text message to selected device
localsend-cli -name "My Laptop" send -text "hello world"  # set a custom alias name
localsend-cli -port 54321 send -text "hello world"  # set a different port number for peer discovery
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
