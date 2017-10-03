Sub Main()
  messagePort = CreateObject("roMessagePort")
  rectangle = CreateObject("roRectangle", 0, 0, 1920, 1080)

  ' set html page source and optionally rotation ("rot270" for counterclockwise rotation)
  ' config = { url: "http://play.playr.biz", transform:"rot90" }
  config = { url: "http://play.playr.biz" }
  htmlWidget = CreateObject("roHtmlWidget", rectangle, config)
  htmlWidget.SetPort(messagePort)

  ' sleep/wait 10 seconds
  sleep(10000)

  htmlWidget.Show()
  while true
    message = wait(0, messagePort)
    print "type(message) = "; type(message)

    if type(message) = "roHtmlWidgetEvent" then
      eventData = message.GetData()
      if type(eventData) = "roAssociativeArray" and type(eventData.reason) = "roString" then
        print "reason = "; eventData.reason
        if eventData.reason = "load-error" then
          print "message = "; eventData.message
        endif
      endif
    endif
  end while
End Sub
