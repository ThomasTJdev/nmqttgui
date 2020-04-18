import
  json,
  os,
  osproc,
  streams,
  strutils,
  times,
  webgui

#
# We are using the binaries generated by nmqtt, we therefore don't need to
# include the library.
#
#include "../nmqtt/src/nmqtt.nim"

let app = newWebView(currentHtmlPath(), title = "nMQTT publish message", height = 835) #, width = 666)

template arg(t, d: string): string =
  if d == "":
    ""
  else:
    t & " \"" & d.replace("\"", "\\\"") & "\""


proc doPublish(data: string) =

  const
    c = "-h $1 -p $2 $3 $4 $5 $6 -q $7 $8 -t $9 -m $10 $11 $12"

  let
    jsn         = parseJson(data)
    clientid    = arg("-c", jsn["clientid"].getStr())
    host        = jsn["host"].getStr()
    port        = jsn["port"].getInt()
    ssl         = if jsn["ssl"].getBool(): "--ssl" else: ""
    username    = arg("-u", jsn["username"].getStr())
    password    = arg("-P", jsn["password"].getStr())
    qos         = jsn["qos"].getInt()
    retain      = if jsn["retain"].getBool(): "--retain" else: ""
    topic       = "\"" & jsn["topic"].getStr().replace("\"", "\\\"") & "\""
    msg         = "\"" & jsn["payload"].getStr().replace("\"", "\\\"") & "\""
    repeat      = if jsn["repeat"].getInt() == 0: "" else: "--repeat " & $jsn["repeat"].getInt()
    repeatdelay = if jsn["repeatdelay"].getInt() == 0: "" else: "--repeat-delay " & $jsn["repeatdelay"].getInt()

    options     = c.format(host, port, ssl, clientid, username, password, qos, retain, topic, msg, repeat, repeatdelay)

  when defined(dev):
    echo options

  if topic == "":
    app.warn("Missing data", "Insert a topic")
    return

  if msg == "":
    app.warn("Missing data", "Insert a payload")
    return

  var
    p = startProcess("nmqtt_pub " & options, options = {poStdErrToStdOut, poEvalCommand})
    outp = outputStream(p)
  close inputStream(p)

  app.js(app.addText("#output", "👑______________________________________________________________👑\n\n" & $now() & "\n\n"))

  var line = newStringOfCap(120).TaintedString
  while true:
    if outp.readLine(line):
      app.js("document.querySelector('#output').scrollTop = document.querySelector('#output').scrollHeight;" &
              app.addText("#output", "" & line.multiReplace([("37m[", ""), ("[37m", ""), ("[0m", "")]) & "\n"))
    else:
      if peekExitCode(p) != -1: break
  close(p)

  app.js(app.addText("#output", "\n👑______________________________________________________________👑\n"))
  app.js("document.querySelector('#output').scrollTop = document.querySelector('#output').scrollHeight;")


  #[
  #
  # The code below integrate directly with nmqtt code. In future versions of nmqtt
  # verbosity will be implemented in the binaries, and we will therefor not need
  # to interact with the code directly. By utilizing the binaries directly, the
  # code maintenance will also be minimal.
  #

  let ctx = newMqttCtx(if clientid != "": clientid else: "nmqttpub-" & $getCurrentProcessId())
  ctx.set_host(host, port, ssl)

  if username != "" or password != "":
    ctx.set_auth(username, password)

  # Set the will message
  #if willretain and (willtopic == "" or willmsg == ""):
  #  echo "Error: Will-retain giving, but no topic given"
  #  quit()
  #elif willtopic != "" and willmsg != "":
  #  ctx.set_will(willtopic, willmsg, willqos, willretain)

  # Connect to broker
  waitFor ctx.connect()
  waitFor sleepAsync(1000)

  # Publish message.
  # If --repeat is specified, repeat N times with Z delay.
  if repeat == 0:
    waitFor ctx.publish(topic, msg, qos, retain)
  else:
    for i in 0..repeat-1:
      waitFor ctx.publish(topic, msg, qos, retain)
      if repeatdelay > 0: waitFor sleepAsync (repeatdelay * 1000)

  # Check that the message has been succesfully send
  while ctx.workQueue.len() > 0:
    waitFor sleepAsync(100)

  # Disconnect from broker
  waitFor ctx.disconnect()

  ]#


app.bindProcs("api"):
  proc jsnPublish(j: string) = doPublish(j)

app.run()
app.exit()
