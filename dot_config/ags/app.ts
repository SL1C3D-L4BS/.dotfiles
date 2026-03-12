import app from "ags/gtk4/app"
import style from "./style.css"
import QuickSettings from "./widget/QuickSettings"

app.start({
  css: style,
  requestHandler(argv: string[], response: (s: string) => void) {
    const cmd = argv[0]
    if (cmd === "toggle" && argv[1] === "quicksettings") {
      try {
        app.toggle_window("quicksettings")
        response("ok")
      } catch (e) {
        response(String(e))
      }
      return
    }
    response(`instance "ags" has no request handler implemented`)
  },
  main() {
    const monitors = app.get_monitors()
    if (monitors.length === 0) return
    QuickSettings(monitors[0]!)
  },
})
