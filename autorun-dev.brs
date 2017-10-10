Sub Main(args)
  url$ = "http://playr.biz/1160/84"

  if args <> invalid and args.Count() > 0 then
    url$ = args[0]
  endif
  print "url = ";url$

  Initialise()
  LogText("url = " + url$)
  CreateHtmlWidget(url$)
  HandleEvents()
End Sub

Function Initialise()
  globalAssociativeArray = GetGlobalAA()

  ' use no or 1 zone (having 1 zone makes the image layer be on top of the video layer by default)
  ' EnableZoneSupport(1)
  EnableZoneSupport(false)

  ' for debuging/diagnostics; open log and serial port
  InitialiseLog()
  InitialiseSerialPort()

  ' Enable mouse cursor
  ' globalAssociativeArray.touchScreen = CreateObject("roTouchScreen")
  ' globalAssociativeArray.touchScreen.EnableCursor(true)

  globalAssociativeArray.messagePort = CreateObject("roMessagePort")

  globalAssociativeArray.gpioPort = CreateObject("roGpioControlPort")
  globalAssociativeArray.gpioPort.SetPort(globalAssociativeArray.messagePort)

  globalAssociativeArray.videoMode = CreateObject("roVideoMode")
  globalAssociativeArray.videoMode.setMode("auto")

  ' set DWS on device
  networkConfiguration = CreateNetworkConfiguration()
  if type(networkConfiguration)= "roNetworkConfiguration" then
    dwsAA = CreateObject("roAssociativeArray")
    dwsAA["port"] = "80"
    networkConfiguration.SetupDWS(dwsAA)
    networkConfiguration.Apply()
  else
  endif

  globalAssociativeArray.networkHotPlug = CreateObject("roNetworkHotplug")
  globalAssociativeArray.networkHotPlug.setPort(globalAssociativeArray.messagePort)
End Function

Sub CreateHtmlWidget(url$ as String)
  globalAssociativeArray = GetGlobalAA()
  width = globalAssociativeArray.videoMode.GetResX()
  height = globalAssociativeArray.videoMode.GetResY()
  rectangle = CreateObject("roRectangle", 0, 0, width, height)

  globalAssociativeArray.htmlWidget = CreateObject("roHtmlWidget", rectangle)
  globalAssociativeArray.htmlWidget.EnableSecurity(false)
  globalAssociativeArray.htmlWidget.EnableCanvas2dAcceleration(true)
  globalAssociativeArray.htmlWidget.ForceGpuRasterization(true)
  globalAssociativeArray.htmlWidget.SetUrl(url$)
  globalAssociativeArray.htmlWidget.EnableJavascript(true)
  ' use only for debugging
  globalAssociativeArray.htmlWidget.StartInspectorServer(2999)
  globalAssociativeArray.htmlWidget.EnableMouseEvents(false)
  globalAssociativeArray.htmlWidget.AllowJavaScriptUrls({ all: "*" })
  globalAssociativeArray.htmlWidget.SetHWZDefault("on")
  globalAssociativeArray.htmlWidget.setPort(globalAssociativeArray.messagePort)
  ' globalAssociativeArray.htmlWidget.SetAppCacheDir()
  ' globalAssociativeArray.htmlWidget.SetAppCacheSize()
  ' globalAssociativeArray.htmlWidget.SetLocalStorageDir()
  ' globalAssociativeArray.htmlWidget.SetLocalStorageQuota()
  globalAssociativeArray.htmlWidget.SetWebDatabaseDir("SD:/webdb")
  globalAssociativeArray.htmlWidget.SetWebDatabaseQuota("2147483648") ' IndexedDB can use 2GB
End Sub

Sub HandleEvents()
  globalAssociativeArray = GetGlobalAA()
  receivedIpAddr = (GetNetworkAddress() <> "")
  receivedLoadFinished = false

  while true
    ' establish receivedIpAddr and receivedLoadFinished
    event = wait(0, globalAssociativeArray.messagePort)
    LogText("Received event " + type(event))
    if type(event) = "roNetworkAttached" then
      LogText("Received roNetworkAttached")
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
        LogText("roGpioButton with value other than 12 ", "info")
      endif
    else
      LogText("Unhandled event: " + type(event), "warning")
    endif

    if receivedIpAddr and receivedLoadFinished then
      LogText("show HTML widget", "info")
      globalAssociativeArray.htmlWidget.Show()
      globalAssociativeArray.htmlWidget.PostJSMessage({msgtype:"htmlloaded"})
      receivedIpAddr = false
      receivedLoadFinished = false
    endif
  endwhile
End Sub

Sub InitialiseLog()
  dateTime = CreateObject("roDateTime")

  ' if there is an existing log file for today, just append to it. otherwise, create a new one to use
  fileName$ = "log-" + dateTime.getYear().ToStr() + dateTime.getMonth().ToStr() + dateTime.getDay().ToStr() + ".txt"
  m.logFile = CreateObject("roAppendFile", fileName$)
  if type(m.logFile) = "roAppendFile" then
    return
  endif

  m.logFile = CreateObject("roCreateFile", fileName$)
End Sub

Sub InitialiseSerialPort()
  globalAssociativeArray = GetGlobalAA()

  globalAssociativeArray.serialPort = CreateObject("roSerialPort", 0, 19200)
  messagePort = CreateObject("roMessagePort")
  globalAssociativeArray.serialPort.SetLineEventPort(messagePort)
End Sub

Sub LogText(text$ as String, level$ as String)
  globalAssociativeArray = GetGlobalAA()
  filler$ = ""
  if level$ = "info" then
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
  ' To use this: msgPort.PostBSMessage({text: "my message"});
  m.logFile.SendLine(text$)
  m.logFile.AsyncFlush()
  globalAssociativeArray.serialPort.SendLine(msg)
End Sub

Sub CreateNetworkConfiguration()
  networkConfiguration = CreateObject("roNetworkConfiguration", 0)
  if type(networkConfiguration) <> "roNetworkConfiguration" then
    networkConfiguration = CreateObject("roNetworkConfiguration", 1)
    if type(networkConfiguration) <> "roNetworkConfiguration" then
      print "Error: network configuration could not be created"
    endif
  endif
  return networkConfiguration
End Sub

Sub GetIPAddress()
  ipAddr = ""
  networkConfiguration = CreateNetworkConfiguration()

  if type(networkConfiguration)= "roNetworkConfiguration" then
    currentConfig = networkConfiguration.GetCurrentConfig()
    if currentConfig.ip4_address <> "" then
      ' We already have an IP addr
      ipAddr = currentConfig.ip4_address
      LogText("Assigned IP address: " + ipAddr)
    endif
  endif
  return ipAddr
End Sub