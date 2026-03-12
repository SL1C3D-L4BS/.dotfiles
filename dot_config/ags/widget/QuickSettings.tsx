import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk, GLib } from "ags/gtk4"
import { Variable, exec, execAsync } from "ags"
import Wp from "gi://AstalWp"
import Network from "gi://AstalNetwork"
import Notifd from "gi://AstalNotifd"

// ─── Volume slider ────────────────────────────────────────────────────────────
function VolumeRow() {
  const audio = Wp.get_default()?.audio
  const sink = audio?.defaultSpeaker

  const volumeIcon = Variable.derive(
    [Variable(sink?.volume ?? 0), Variable(sink?.mute ?? false)],
    (vol, muted) => {
      if (muted || vol === 0) return "󰖁"
      if (vol < 0.33) return "󰕿"
      if (vol < 0.66) return "󰖀"
      return "󰕾"
    }
  )

  return (
    <box cssName="qs-row" orientation={Gtk.Orientation.HORIZONTAL}>
      <label cssName="qs-icon" label={volumeIcon()} />
      <box orientation={Gtk.Orientation.VERTICAL} hexpand>
        <label cssName="qs-label" label="Volume" halign={Gtk.Align.START} />
        <slider
          cssName="qs-slider"
          hexpand
          min={0}
          max={1.5}
          value={sink?.volume ?? 0}
          onChangeValue={(self) => {
            if (sink) sink.volume = self.value
          }}
        />
      </box>
      <button
        cssName="qs-icon-btn"
        onClicked={() => {
          if (sink) sink.mute = !sink.mute
        }}
        label={sink?.mute ? "󰖁" : "󰖀"}
      />
    </box>
  )
}

// ─── Brightness slider ────────────────────────────────────────────────────────
function BrightnessRow() {
  const brightness = Variable(50)

  const fetchBrightness = async () => {
    try {
      const cur = await execAsync("brightnessctl get")
      const max = await execAsync("brightnessctl max")
      brightness.set(Math.round((parseInt(cur) / parseInt(max)) * 100))
    } catch (_) {}
  }
  fetchBrightness()

  const setBrightness = async (pct: number) => {
    try {
      await execAsync(`brightnessctl set ${pct}%`)
      brightness.set(pct)
    } catch (_) {}
  }

  return (
    <box cssName="qs-row" orientation={Gtk.Orientation.HORIZONTAL}>
      <label cssName="qs-icon" label="󰃟" />
      <box orientation={Gtk.Orientation.VERTICAL} hexpand>
        <label cssName="qs-label" label="Brightness" halign={Gtk.Align.START} />
        <slider
          cssName="qs-slider"
          hexpand
          min={5}
          max={100}
          value={brightness()}
          onChangeValue={(self) => setBrightness(Math.round(self.value))}
        />
      </box>
    </box>
  )
}

// ─── Network row ──────────────────────────────────────────────────────────────
function NetworkRow() {
  const network = Network.get_default()
  const wifi = network?.wifi

  const ssid = Variable(wifi?.ssid ?? "Disconnected")
  const icon = Variable(wifi?.iconName ?? "network-wireless-offline-symbolic")

  if (wifi) {
    const update = () => {
      ssid.set(wifi.ssid ?? (wifi.enabled ? "Connecting…" : "Wi-Fi off"))
      icon.set(wifi.iconName ?? "network-wireless-offline-symbolic")
    }
    wifi.connect("notify::ssid", update)
    wifi.connect("notify::icon-name", update)
    update()
  }

  return (
    <box cssName="qs-row" orientation={Gtk.Orientation.HORIZONTAL}>
      <label cssName="qs-icon" label="" />
      <box orientation={Gtk.Orientation.VERTICAL} hexpand>
        <label cssName="qs-label" label="Network" halign={Gtk.Align.START} />
        <label cssName="qs-sublabel" label={ssid()} halign={Gtk.Align.START} />
      </box>
      <switch
        cssName="qs-switch"
        active={wifi?.enabled ?? false}
        onStateSet={(self, state) => {
          if (wifi) wifi.enabled = state
          return false
        }}
      />
    </box>
  )
}

// ─── DND toggle ────────────────────────────────────────────────────────────────
function DNDRow() {
  const dnd = Variable(false)

  const toggle = async () => {
    const current = dnd.get()
    try {
      if (current) {
        await execAsync("makoctl mode -r do-not-disturb")
      } else {
        await execAsync("makoctl mode -a do-not-disturb")
      }
      dnd.set(!current)
    } catch (_) {}
  }

  const label = Variable.derive([dnd], (v) => v ? "DND On" : "DND Off")

  return (
    <box cssName="qs-row" orientation={Gtk.Orientation.HORIZONTAL}>
      <label cssName="qs-icon" label={dnd((v) => v ? "󰂛" : "󰂚")} />
      <box hexpand orientation={Gtk.Orientation.VERTICAL}>
        <label cssName="qs-label" label="Do Not Disturb" halign={Gtk.Align.START} />
        <label cssName="qs-sublabel" label={label()} halign={Gtk.Align.START} />
      </box>
      <switch
        cssName="qs-switch"
        active={dnd()}
        onStateSet={(self, state) => {
          toggle()
          return false
        }}
      />
    </box>
  )
}

// ─── Power row ────────────────────────────────────────────────────────────────
function PowerRow() {
  const actions = [
    { icon: "", label: "Lock",     cmd: "loginctl lock-session" },
    { icon: "⏾", label: "Sleep",   cmd: "systemctl suspend" },
    { icon: "󰗽", label: "Logout",  cmd: "hyprctl dispatch exit" },
    { icon: "󰑓", label: "Reboot",  cmd: "systemctl reboot" },
    { icon: "⏻", label: "Power",   cmd: "systemctl poweroff" },
  ]

  return (
    <box cssName="qs-power-row" orientation={Gtk.Orientation.HORIZONTAL} halign={Gtk.Align.CENTER}>
      {actions.map((a) => (
        <button
          cssName="qs-power-btn"
          tooltipText={a.label}
          onClicked={() => {
            app.toggle_window("quicksettings")
            execAsync(["sh", "-c", a.cmd]).catch(() => {})
          }}
        >
          <label label={a.icon} />
        </button>
      ))}
    </box>
  )
}

// ─── Quick action pills ────────────────────────────────────────────────────────
function QuickActions() {
  const actions = [
    { icon: "", label: "Screenshot", cmd: ["bash", "-c", `${GLib.get_home_dir()}/.config/hypr/scripts/screenshot.sh region`] },
    { icon: "󰅌", label: "Clipboard",  cmd: ["bash", "-c", `cliphist list | fuzzel --dmenu --lines=12 --width=52 --prompt="Clipboard: " | cliphist decode | wl-copy`] },
    { icon: "󰒱", label: "Reload Hypr", cmd: ["hyprctl", "reload"] },
  ]

  return (
    <box cssName="qs-quick-actions" orientation={Gtk.Orientation.HORIZONTAL}>
      {actions.map((a) => (
        <button
          cssName="qs-quick-btn"
          tooltipText={a.label}
          onClicked={() => {
            app.toggle_window("quicksettings")
            execAsync(a.cmd).catch(() => {})
          }}
        >
          <box orientation={Gtk.Orientation.VERTICAL}>
            <label cssName="qs-quick-icon" label={a.icon} />
            <label cssName="qs-quick-label" label={a.label} />
          </box>
        </button>
      ))}
    </box>
  )
}

// ─── Header ───────────────────────────────────────────────────────────────────
function Header() {
  const time = Variable("")
  const tick = () => {
    const d = new Date()
    time.set(
      d.toLocaleTimeString("en-US", { hour: "2-digit", minute: "2-digit", hour12: true })
    )
  }
  tick()
  const interval = setInterval(tick, 10000)

  return (
    <box cssName="qs-header" orientation={Gtk.Orientation.HORIZONTAL}>
      <box orientation={Gtk.Orientation.VERTICAL} hexpand>
        <label cssName="qs-title" label="Quick Settings" halign={Gtk.Align.START} />
        <label cssName="qs-time" label={time()} halign={Gtk.Align.START} />
      </box>
      <button
        cssName="qs-close-btn"
        onClicked={() => app.toggle_window("quicksettings")}
        label="×"
      />
    </box>
  )
}

// ─── Root panel ───────────────────────────────────────────────────────────────
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
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.ON_DEMAND}
      onKeyPressEvent={(self, event) => {
        if (event.get_keyval()[1] === Gdk.KEY_Escape) {
          self.visible = false
        }
      }}
    >
      <box cssName="qs-panel" orientation={Gtk.Orientation.VERTICAL}>
        <Header />
        <box cssName="qs-divider" />
        <QuickActions />
        <box cssName="qs-divider" />
        <VolumeRow />
        <BrightnessRow />
        <box cssName="qs-divider" />
        <NetworkRow />
        <DNDRow />
        <box cssName="qs-divider" />
        <PowerRow />
      </box>
    </window>
  )
}
