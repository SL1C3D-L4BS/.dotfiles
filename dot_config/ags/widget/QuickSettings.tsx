import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"

export default function QuickSettings(gdkmonitor: Gdk.Monitor) {
  const { TOP, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible={false}
      name="quicksettings"
      class="QuickSettings"
      gdkmonitor={gdkmonitor}
      anchor={TOP | RIGHT}
      application={app}
    >
      <box orientation={Gtk.Orientation.VERTICAL} cssName="panel">
        <label cssName="title" label="Quick Settings" halign={Gtk.Align.START} />
        <box cssName="row" orientation={Gtk.Orientation.VERTICAL}>
          <button cssName="btn" onClicked={() => app.toggle_window("quicksettings")}>
            <label label="Close" />
          </button>
        </box>
      </box>
    </window>
  )
}
