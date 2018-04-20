Sub Main(args as Dynamic)
  print "autorun.brs started"

  ' Default URL for playing Bizplay content
  ' url$ = "http://play.playr.biz"
  ' Specific Bizplay channel for testing BrightSign player capabilities and performance
  url$ = "http://www..playr.biz/1160/84"
  ' Specific URL for testing YouTube video playback
  ' url$ = "http://playr.biz/videotest/manual/youtube.html"
  ' Specific URL for testing Vimeo video playback
  ' url$ = "http://playr.biz/videotest/manual/vimeo.html"
  if args <> invalid and args.Count() > 0 then
    url$ = args[0]
  endif

  Initialise(url$)
  HandleEvents()
EndSub

Sub HandleEvents()
  LogText("HandleEvents start", "info")
  globalAssociativeArray = GetGlobalAA()
  receivedIpAddr = (GetIPAddress() <> "")
  receivedLoadFinished = false

  while true
    ' establish receivedIpAddr and receivedLoadFinished
    event = wait(0, globalAssociativeArray.messagePort)
    LogText("HandleEvents: Received event: " + type(event), "info")
    if type(event) = "roNetworkAttached" then
      LogText("HandleEvents: Received roNetworkAttached", "info")
      receivedIpAddr = true
    else if type(event) = "roHtmlWidgetEvent" then
      eventData = event.GetData()
      if type(eventData) = "roAssociativeArray" and type(eventData.reason) = "roString" then
        if eventData.reason = "load-error" then
          LogText("HandleEvents: HTML load error: " + eventData.message, "error")
        else if eventData.reason = "load-started" then
          LogText("HandleEvents: Received load started", "info")
        else if eventData.reason = "load-finished" then
          LogText("HandleEvents: Received load finished", "info")
          receivedLoadFinished = true
        else if eventData.reason = "message" then
          LogText("HandleEvents: Received message: " + eventData.message.text, "info")
        else
          LogText("HandleEvents: Unknown eventData.reason: " + eventData.reason, "warning")
        endif
      else
        LogText("HandleEvents: Unknown eventData: " + type(eventData), "warning")
      endif
    else if type(event) = "roGpioButton" then
      if event.GetInt() = 12 then
        LogText("HandleEvents: roGpioButton with value 12 => Stopping", "info")
        stop
      else
        LogText("HandleEvents: roGpioButton with value other than 12", "info")
      endif
    else
      LogText("HandleEvents: Unhandled event: " + type(event), "warning")
    endif

    if receivedIpAddr and receivedLoadFinished then
      LogText("HandleEvents: Show HTML widget", "info")
      globalAssociativeArray.htmlWidget.Show()
      globalAssociativeArray.htmlWidget.PostJSMessage({msgtype:"htmlloaded"})
      receivedIpAddr = false
      receivedLoadFinished = false
    else
      if receivedIpAddr then
        LogText("HandleEvents: receivedIpAddr: true", "info")
      else
        LogText("HandleEvents: receivedIpAddr: false", "warning")
      endif
      if receivedLoadFinished then
        LogText("HandleEvents: receivedLoadFinished: true", "info")
      else
        LogText("HandleEvents: receivedLoadFinished: false", "warning")
      endif
    endif
  endwhile
EndSub

Sub LogText(text$ as String, level$ as String)
  globalAssociativeArray = GetGlobalAA()
  filler$ = ""
  if level$ = "info" then
    filler$ = "I: "
  else if level$ = "warning" then
    filler$ = "W: "
  else if level$ = "error" then
    filler$ = ">> E: "
  else if level$ = "fatal" then
    filler$ = ">>!! F: "
  else
    filler$ = ""
  endif

  print filler$;text$
  if type(m.logFile) = "roAppendFile" then
    ' To use this: msgPort.PostBSMessage({text: "my message"});
    m.logFile.SendLine(filler$ + text$)
    m.logFile.AsyncFlush()
  endif
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

  if type(globalAssociativeArray.networkConfiguration) = "roNetworkConfiguration" then
    currentConfig = globalAssociativeArray.networkConfiguration.GetCurrentConfig()
    if currentConfig.ip4_address <> "" then
      ' We already have an IP addr
      ipAddr = currentConfig.ip4_address
      LogText("GetIPAddress: Assigned IP address: " + ipAddr, "info")
    else
      LogText("GetIPAddress: no IP address found", "info")
    endif
  else
    LogText("GetIPAddress: no networkConfiguration found", "error")
  endif

  LogText("GetIPAddress end", "info")
  return ipAddr
EndFunction

Sub Initialise(url$ as String)
  LogText("Initialise start", "info")
  globalAssociativeArray = GetGlobalAA()

  ' use no or 1 zone (having 1 zone makes the image layer be on top of the video layer by default)
  ' EnableZoneSupport(1)
  EnableZoneSupport(false)

  ' for debuging/diagnostics; open log and serial port
  InitialiseLog()
  LogText("*******************************************************************", "info")
  systemTime = CreateObject("roSystemTime")
  dateTime = systemTime.GetLocalDateTime()
  LogText("****************      " + dateTime.GetString() + "      ****************", "info")
  LogText("*******************************************************************", "info")
  InitialiseSerialPort()
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
  InitialiseNetworkConfiguration()

  globalAssociativeArray.networkHotPlug = CreateObject("roNetworkHotplug")
  globalAssociativeArray.networkHotPlug.setPort(globalAssociativeArray.messagePort)
  LogText("Initialise end", "info")
EndSub

Sub InitialiseHtmlWidget(url$ as String)
  LogText("InitialiseHtmlWidget start", "info")
  LogText("InitialiseHtmlWidget: url = " + url$, "info")
  globalAssociativeArray = GetGlobalAA()
  if type(globalAssociativeArray.videoMode) = "roVideoMode"
    width = globalAssociativeArray.videoMode.GetResX()
    height = globalAssociativeArray.videoMode.GetResY()
  else
    width = 1920
    height = 1080
  endif
  rectangle = CreateObject("roRectangle", 0, 0, width, height)

  ' don't use the option hash as a third argument since that freezes
  ' all related settings and makes changing them using the mthods impossible
  globalAssociativeArray.htmlWidget = CreateObject("roHtmlWidget", rectangle)
  globalAssociativeArray.htmlWidget.SetUrl(url$)
  globalAssociativeArray.htmlWidget.EnableSecurity(false)
  globalAssociativeArray.htmlWidget.EnableJavascript(true)
  globalAssociativeArray.htmlWidget.AllowJavaScriptUrls({ all: "*" })
  globalAssociativeArray.htmlWidget.EnableMouseEvents(false)
  globalAssociativeArray.htmlWidget.SetHWZDefault("on")
  globalAssociativeArray.htmlWidget.EnableCanvas2dAcceleration(true)
  globalAssociativeArray.htmlWidget.ForceGpuRasterization(true) ' on by default
  globalAssociativeArray.htmlWidget.setPort(globalAssociativeArray.messagePort)
  globalAssociativeArray.htmlWidget.SetAppCacheDir("SD:/appcache")
  globalAssociativeArray.htmlWidget.SetAppCacheSize(67108864) ' 64 MB
  globalAssociativeArray.htmlWidget.SetLocalStorageDir("SD:/storage")
  globalAssociativeArray.htmlWidget.SetLocalStorageQuota(67108864) ' 64 MB
  globalAssociativeArray.htmlWidget.SetWebDatabaseDir("SD:/webdb")
  globalAssociativeArray.htmlWidget.SetWebDatabaseQuota("2147483648") ' IndexedDB video cache: 2GB
  ' use only for debugging
  ' globalAssociativeArray.htmlWidget.StartInspectorServer(2999)
  LogText("InitialiseHtmlWidget end", "info")
EndSub

Sub InitialiseLog()
  LogText("InitialiseLog start", "info")
  systemTime = CreateObject("roSystemTime")
  dateTime = systemTime.GetLocalDateTime()

  ' if there is an existing log file for today, just append to it. otherwise, create a new one to use
  fileName$ = "log-" + dateTime.GetYear().ToStr() + dateTime.GetMonth().ToStr() + dateTime.GetDay().ToStr() + ".txt"
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
  LogText("InitialiseSerialPort end", "info")
EndSub

Sub InitialiseNetworkConfiguration()
  LogText("InitialiseNetworkConfiguration start", "info")
  globalAssociativeArray = GetGlobalAA()

  globalAssociativeArray.networkConfiguration = CreateNetworkConfiguration()
  if type(globalAssociativeArray.networkConfiguration)= "roNetworkConfiguration" then
    LogText("InitialiseNetworkConfiguration: network configuration created", "info")
    dwsAA = CreateObject("roAssociativeArray")
    dwsAA["port"] = "80"
    globalAssociativeArray.networkConfiguration.SetupDWS(dwsAA)
    globalAssociativeArray.networkConfiguration.Apply()
    LogText("InitialiseNetworkConfiguration: network configuration has been applied", "info")
  else
    LogText("InitialiseNetworkConfiguration: network configuration could not be created", "error")
  endif
  LogText("InitialiseNetworkConfiguration end", "info")
EndSub
