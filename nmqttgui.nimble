# Package
version       = "0.0.1"
author        = "ThomasTJdev"
description   = "GUI for nmqtt"
license       = "MIT"
srcDir        = "src"
bin           = @["nmqttgui"]


# Dependencies
requires "nim >= 1.0.6"
requires "webgui >= 0.6.0"
requires "nmqtt >= 0.1.0"

# We are using the binaries from nmqtt, it is therefor not necessary to
# get the code of nmqtt - the binaries are fine.
#
#task setup, "Download nmqtt repo":
#  exec("git clone https://github.com/zevv/nmqtt.git")
#
#before build:
#  setupTask()
#
#before install:
#  setupTask()
