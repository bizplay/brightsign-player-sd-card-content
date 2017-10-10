Sub Main()
  messagePort = CreateObject("roMessagePort")
  rectangle = CreateObject("roRectangle", 0, 0, 1920, 1080)

  ' config = {
  ' nodejs_enabled:(Boolean) Enables Node.js on the widget. This value is False by default.
  ' focus_enabled:(Boolean) Enables focus for mouse/touchscreen events.
  ' mouse_enabled:(Boolean) Enables mouse/touchscreen events. This value is False by default.
  ' scrollbar_enabled:(Boolean) Enables automatic scrollbars for content that does not fit into the viewport. This value is False by default.
  ' force_gpu_rasterization_enabled:(Boolean) Enables GPU rasterization for HTML graphics. This value is True by default.
  ' canvas_2d_acceleration_enabled:(Boolean) Enables 2D canvas acceleration. This will improve the framerate of most HTML pages that use 2D animations, but can cause out-of-memory issues with pages that use a large number of off-screen canvas surfaces.
  ' javascript_enabled:(Boolean) Enables JavaScript on the widget. This value is True by default.
  ' brightsign_js_objects_enabled:(Boolean) Enables BrightScript-JavaScript objects. This value is False by default.
  ' transform:(string) Sets the screen orientation of content in the widget (note that the coordinates and dimensions of the roRectangle containing the widget are  not affected by rotation). The following values are accepted:
  '   "identity": There is no transform (i.e. the widget content is oriented as landscape). This is the default setting.
  '   "rot90": The widget content is rotated to portrait at 90 degrees (counter-clockwise).
  '   "rot270": The widget content is rotated to portrait at 270 degrees (counter-clockwise).
  ' user_agent:(string) Modifies the default user-agent string for the roHtmlWidget instance.
  ' url:(string) The URL to use for display. See the SetUrl() entry below for more information on using URIs to access files from local storage.
  ' user_stylesheet:(string) Applies the specified user stylesheet to pages in the widget. The parameter is a URI specifying any file: resource in the storage. The stylesheet can also be specified as inline data.
  ' hwz_default:(string) Specifies the default HWZ behavior. See the SetHWZDefault() entry below for more information.
  ' storage_path:(string) Creates a "Local Storage" subfolder in the specified directory. This folder is used by local storage applications such as the JavaScript storage class.
  ' storage_quota:(double or string) Sets the total size (in bytes) allotted to all local storage applications (including IndexedDB). The default total size is 5MB.
  ' fonts:(roArray) Specifies a list of TFF font files that can be accessed by the webpage. Font files are specified as an array of string filenames.
  ' pcm_audio_outputs:(roArray) Configures the PCM audio output for the HTML widget. Outputs are specified as an array of roAudioOutput instances.
  ' compressed_audio_outputs:(roArray) Configures compressed audio output (e.g. Dolby AC3 encoded audio) for the HTML widget. Outputs are specified as an array of roAudioOutput instances.
  ' multi_channel_audio_outputs:(roArray) Configures multi-channel audio output for the HTML widget. Outputs are specified as an array of roAudioOutput instances.
  ' inspector_server:(roAssociativeArray) Configures the Chromium Inspector for the widget.
  ' ip_addr:(string) The Inspector IP address. This value is useful if the player is assigned more than one IP address (i.e. there are multiple network interfaces) and you wish to limit the Inspector server to one. The default value is "0.0.0.0", which allows the Inspector to accept connections using either IP address.
  ' port:(integer) The port for the Inspector server.
  ' security_params:(roAssociativeArray) Enables or disables Chromium security checks for cross-origin requests, local video playback from HTTP, etc.
  ' feature:(string) The security feature to be enabled. Accepted values are "websecurity" and "camera_enabled".
  ' enabled:(bool) Enables or disables the security feature.
  ' }
  ' config = {
  '   url: "http://playr.biz/1160/84",
  '   nodejs_enabled: false,
  '   focus_enabled: false,
  '   mouse_enabled: false,
  '   scrollbar_enabled: false,
  '   force_gpu_rasterization_enabled: true,
  '   canvas_2d_acceleration_enabled: true,
  '   javascript_enabled: true,
  '   brightsign_js_objects_enabled: false,
  '   transform: "identity",
  '   hwz_default: "on"
  ' }
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

Sub CreateHtmlWidget(url$ as String)
  gaa = GetGlobalAA()
  width = gaa.vm.GetResX()
  height = gaa.vm.GetResY()
  rect = CreateObject("roRectangle", 0, 0, width, height)

  gaa.htmlWidget = CreateObject("roHtmlWidget", rect)
  gaa.htmlWidget.EnableSecurity(false)
  gaa.htmlWidget.SetUrl(url$)
  gaa.htmlWidget.EnableJavascript(true)
  gaa.htmlWidget.StartInspectorServer(2999)
  gaa.htmlWidget.EnableMouseEvents(true)
  gaa.htmlWidget.AllowJavaScriptUrls({ all: "*" })
  gaa.htmlWidget.SetHWZDefault("on")
  gaa.htmlWidget.setPort(gaa.mp)
E
