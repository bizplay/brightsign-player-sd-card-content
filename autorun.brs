Sub Main()
  msgPort = CreateObject("roMessagePort")
  rectangle = CreateObject("roRectangle", 0, 0, 1920, 1080)

  ' set html page source and optionally rotation ("rot270" for counterclockwise rotation)
  ' config = { url: "http://play.playr.biz", transform:"rot90" }
  config = { url: "http://play.playr.biz" }
  htmlWidget = CreateObject("roHtmlWidget", rectangle, config)
  htmlWidget.SetPort(msgPort)

  ' sleep/wait 10 seconds
  sleep(10000)

  h.Show()
  while true
    msg = wait(0, msgPort)
    print "type(msg) = "; type(msg)

    if type(msg) = "roHtmlWidgetEvent" then
      eventData = msg.GetData()
      if type(eventData) = "roAssociativeArray" and type(eventData.reason) = "roString" then
        print "reason = "; eventData.reason
        if eventData.reason = "load-error" then
          print "message = "; eventData.message
        endif
      endif
    endif
  end while
End Sub
