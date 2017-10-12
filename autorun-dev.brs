Sub Main(args)
  print "autorun.brs started"
  tmpFile = CreateObject("roCreateFile", "main0.txt")
  url$ = "http://playr.biz/1160/84"

  if args <> invalid and args.Count() > 0 then
    url$ = args[0]
  endif

  tmpFile = CreateObject("roCreateFile", "main1.txt")
  Initialise(url$)
  tmpFile = CreateObject("roCreateFile", "main2.txt")
  LogText("url = " + url$, "info")
  ' CreateHtmlWidget(url$)

  ' sleep/wait 10 seconds
  sleep(10000)
  tmpFile = CreateObject("roCreateFile", "main3.txt")
  globalAssociativeArray = GetGlobalAA()

  globalAssociativeArray.htmlWidget.Show()
  tmpFile = CreateObject("roCreateFile", "main4.txt")

  ' HandleEvents()
  while true
    message = wait(0, globalAssociativeArray.messagePort)
    LogText("type(message) = " + type(message), "info")
    if type(message) = "roHtmlWidgetEvent" then
      eventData = message.GetData()
      if type(eventData) = "roAssociativeArray" and type(eventData.reason) = "roString" then
        LogText("reason = " + eventData.reason, "info")
        if eventData.reason = "load-error" then
          LogText("message = " + eventData.message, "error")
        endif
      endif
    endif
  end while
EndSub

Sub HandleEvents()
  LogText("HandleEvents start", "info")
  globalAssociativeArray = GetGlobalAA()
  receivedIpAddr = (GetIPAddress() <> "")
  receivedLoadFinished = false

  while true
    ' establish receivedIpAddr and receivedLoadFinished
    event = wait(0, globalAssociativeArray.messagePort)
    LogText("Received event " + type(event), "info")
    if type(event) = "roNetworkAttached" then
      LogText("Received roNetworkAttached", "info")
      receivedIpAddr = true
    else if type(event) = "roHtmlWidgetEvent" then
      eventData = event.GetData()
      if type(eventData) = "roAssociativeArray" and type(eventData.reason) = "roString" then
        if eventData.reason = "load-error" then
          LogText("HTML load error: " + eventData.message, "error")
        else if eventData.reason = "load-finished" then
          LogText("Received load finished", "info")
          receivedLoadFinished = true
        else if eventData.reason = "message" then
          LogText(eventData.message.text, "info")
        else
          LogText("Unknown eventData.reason: " + eventData.reason, "warning")
        endif
      else
        LogText("Unknown eventData: " + type(eventData), "warning")
      endif
    else if type(event) = "roGpioButton" then
      if event.GetInt() = 12 then
        stop
      else
        LogText("roGpioButton with value other than 12", "info")
      endif
    else
      LogText("Unhandled event: " + type(event), "warning")
    endif

    if receivedIpAddr and receivedLoadFinished then
      LogText("Show HTML widget", "info")
      globalAssociativeArray.htmlWidget.Show()
      globalAssociativeArray.htmlWidget.PostJSMessage({msgtype:"htmlloaded"})
      receivedIpAddr = false
      receivedLoadFinished = false
    endif
  endwhile
EndSub

Sub LogText(text$ as String, level$ as String)
  globalAssociativeArray = GetGlobalAA()
  filler$ = ""
  if level$ = "info" then
    filler$ = ""
  else if level$ = "warning" then
    filler$ = "===> "
  else if level$ = "error" then
    filler$ = "!!!! "
  else if level$ = "fatal" then
    filler$ = "<<!!!!>> "
  else
    filler$ = ""
  endif

  print filler$;text$
  if type(m.logFile) = "roAppendFile" then
    ' To use this: msgPort.PostBSMessage({text: "my message"});
    m.logFile.SendLine(filler$ + text$)
    m.logFile.AsyncFlush()
  end
  if type(globalAssociativeArray.serialPort) = "roSerialPort" then
    globalAssociativeArray.serialPort.SendLine(filler$ + text$)
  endif
EndSub

Function CreateNetworkConfiguration() as Object
  LogText("CreateNetworkConfiguration start", "info")
  networkConfiguration = CreateObject("roNetworkConfiguration", 0)
  if type(networkConfiguration) <> "roNetworkConfiguration" then
    networkConfiguration = CreateObject("roNetworkConfiguration", 1)
    if type(networkConfiguration) <> "roNetworkConfiguration" then
      LogText("Network configuration could not be created", "error")
    endif
  endif

  LogText("CreateNetworkConfiguration end", "info")
  return networkConfiguration
EndFunction

Function GetIPAddress() as String
  LogText("GetIPAddress start", "info")
  ipAddr = ""
  globalAssociativeArray = GetGlobalAA()
  ' networkConfiguration = CreateNetworkConfiguration()

  if type(globalAssociativeArray.networkConfiguration) = "roNetworkConfiguration" then
    currentConfig = networkConfiguration.GetCurrentConfig()
    if currentConfig.ip4_address <> "" then
      ' We already have an IP addr
      ipAddr = currentConfig.ip4_address
      LogText("Assigned IP address: " + ipAddr, "info")
    endif
  endif

  LogText("GetIPAddress end", "info")
  return ipAddr
EndFunction

Sub Initialise(url$ as String)
  LogText("Initialise start", "info")
  globalAssociativeArray = GetGlobalAA()

  ' use no or 1 zone (having 1 zone makes the image layer be on top of the video layer by default)
  ' EnableZoneSupport(1)
  ' EnableZoneSupport(false)

  ' for debuging/diagnostics; open log and serial port
  InitialiseLog()
  ' InitialiseSerialPort()
  ' Enable mouse cursor
  ' globalAssociativeArray.touchScreen = CreateObject("roTouchScreen")
  ' globalAssociativeArray.touchScreen.EnableCursor(true)

  globalAssociativeArray.messagePort = CreateObject("roMessagePort")

  globalAssociativeArray.gpioPort = CreateObject("roGpioControlPort")
  globalAssociativeArray.gpioPort.SetPort(globalAssociativeArray.messagePort)

  globalAssociativeArray.videoMode = CreateObject("roVideoMode")
  globalAssociativeArray.videoMode.setMode("auto")

  InitialiseHtmlWidget(url$)

  ' set DWS on device
  ' globalAssociativeArray.networkConfiguration = CreateNetworkConfiguration()
'  InitialiseNetworkConfiguration()
  ' if type(globalAssociativeArray.networkConfiguration)= "roNetworkConfiguration" then
  '   dwsAA = CreateObject("roAssociativeArray")
  '   dwsAA["port"] = "80"
  '   globalAssociativeArray.networkConfiguration.SetupDWS(dwsAA)
  '   globalAssociativeArray.networkConfiguration.Apply()
  '   LogText("Network configuration has been applied", "info")
  ' else
  '   LogText("Network configuration could not be created", "error")
  ' endif

  globalAssociativeArray.networkHotPlug = CreateObject("roNetworkHotplug")
  globalAssociativeArray.networkHotPlug.setPort(globalAssociativeArray.messagePort)
  LogText("Initialise end", "info")
EndSub

Sub InitialiseHtmlWidget(url$ as String)
  LogText("InitialiseHtmlWidget start", "info")
  globalAssociativeArray = GetGlobalAA()
  if type(globalAssociativeArray.videoMode) = "roVideoMode"
    width = globalAssociativeArray.videoMode.GetResX()
    height = globalAssociativeArray.videoMode.GetResY()
  else
    width = 1920
    height = 1080
  endif
  rectangle = CreateObject("roRectangle", 0, 0, width, height)

  globalAssociativeArray.htmlWidget = CreateObject("roHtmlWidget", rectangle)
  globalAssociativeArray.htmlWidget.SetUrl(url$)
  globalAssociativeArray.htmlWidget.EnableSecurity(false)
  globalAssociativeArray.htmlWidget.EnableJavascript(true)
  globalAssociativeArray.htmlWidget.AllowJavaScriptUrls({ all: "*" })
  ' use only for debugging
  ' globalAssociativeArray.htmlWidget.StartInspectorServer(2999)
  globalAssociativeArray.htmlWidget.EnableMouseEvents(false)
  globalAssociativeArray.htmlWidget.SetHWZDefault("on")
  globalAssociativeArray.htmlWidget.EnableCanvas2dAcceleration(true)
  globalAssociativeArray.htmlWidget.ForceGpuRasterization(true)
  globalAssociativeArray.htmlWidget.setPort(globalAssociativeArray.messagePort)
  ' globalAssociativeArray.htmlWidget.SetAppCacheDir()
  ' globalAssociativeArray.htmlWidget.SetAppCacheSize()
  ' globalAssociativeArray.htmlWidget.SetLocalStorageDir()
  ' globalAssociativeArray.htmlWidget.SetLocalStorageQuota()
  ' globalAssociativeArray.htmlWidget.SetWebDatabaseDir("SD:/webdb")
  ' globalAssociativeArray.htmlWidget.SetWebDatabaseQuota("2147483648") ' IndexedDB can use 2GB
  LogText("InitialiseHtmlWidget end", "info")
EndSub

Sub InitialiseLog()
  LogText("InitialiseLog start", "info")
  ' dateTime = CreateObject("roDateTime")

  ' if there is an existing log file for today, just append to it. otherwise, create a new one to use
  ' fileName$ = "log-" + dateTime.getYear().ToStr() + dateTime.getMonth().ToStr() + dateTime.getDay().ToStr() + ".txt"
  fileName$ = "log.txt"
  m.logFile = CreateObject("roAppendFile", fileName$)
  if type(m.logFile) = "roAppendFile" then
    return
  endif

  m.logFile = CreateObject("roCreateFile", fileName$)
  LogText("InitialiseLog end", "info")
EndSub

Sub InitialiseSerialPort()
  LogText("InitialiseSerialPort start", "info")
  globalAssociativeArray = GetGlobalAA()

  globalAssociativeArray.serialPort = CreateObject("roSerialPort", 0, 19200)
  if type(globalAssociativeArray.serialPort) = "roSerialPort" then
    ' use the global message port
    ' messagePort = CreateObject("roMessagePort")
    globalAssociativeArray.serialPort.SetLineEventPort(globalAssociativeArray.messagePort)
  else
    LogText("Serial port could not be created", "error")
  endif
EndSub

Sub InitialiseNetworkConfiguration()
  LogText("InitialiseNetworkConfiguration start", "info")
  globalAssociativeArray = GetGlobalAA()

  globalAssociativeArray.networkConfiguration = CreateNetworkConfiguration()
  if type(globalAssociativeArray.networkConfiguration)= "roNetworkConfiguration" then
    dwsAA = CreateObject("roAssociativeArray")
    dwsAA["port"] = "80"
    globalAssociativeArray.networkConfiguration.SetupDWS(dwsAA)
    globalAssociativeArray.networkConfiguration.Apply()
    LogText("Network configuration has been applied", "info")
  else
    LogText("Network configuration could not be created", "error")
  endif
  LogText("InitialiseNetworkConfiguration end", "info")
EndSub
