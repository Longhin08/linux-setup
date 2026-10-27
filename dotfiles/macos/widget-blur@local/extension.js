const Main = imports.ui.main;
const Gio = imports.gi.Gio;
const GLib = imports.gi.GLib;

const DIR = GLib.get_home_dir() + '/.local/share/widget-blur';
const SCRIPT = DIR + '/make-blur.py';
const FRAME = 'border-radius: 24px; border: 1px solid rgba(255,255,255,0.14); ' +
    'box-shadow: 0 8px 24px rgba(0,0,0,0.30); background-color: transparent;';

let bgSettings, bgSignal, addSignal, image = null, tracked = [];

function style(actor) {
    if (!image)
        return;
    let [x, y] = actor.get_transformed_position();
    let mon = Main.layoutManager.primaryMonitor;
    actor.set_style(FRAME +
        ` background-image: url("${image}");` +
        ` background-size: ${mon.width}px ${mon.height}px;` +
        ` background-position: ${-Math.round(x)}px ${-Math.round(y)}px;`);
}

function track(actor) {
    let id = actor.connect('notify::allocation', () => style(actor));
    tracked.push([actor, id]);
    style(actor);
}

function styleAll() {
    Main.deskletContainer.actor.get_children().forEach(style);
}

function regenerate() {
    let out = `${DIR}/blur-${Date.now()}.png`;
    let proc = Gio.Subprocess.new(['python3', '-I', SCRIPT, out], Gio.SubprocessFlags.NONE);
    proc.wait_async(null, (p, res) => {
        p.wait_finish(res);
        if (!p.get_successful())
            return;
        let old = image;
        image = out;
        styleAll();
        if (old)
            Gio.File.new_for_path(old).delete_async(GLib.PRIORITY_DEFAULT, null, null);
    });
}

function init() {}

function enable() {
    let c = Main.deskletContainer.actor;
    c.get_children().forEach(track);
    addSignal = c.connect('actor-added', (_c, actor) => track(actor));
    bgSettings = new Gio.Settings({ schema_id: 'org.cinnamon.desktop.background' });
    bgSignal = bgSettings.connect('changed::picture-uri', regenerate);
    // drop stale images from previous sessions, then build a fresh one
    let e = Gio.File.new_for_path(DIR).enumerate_children('standard::name', 0, null), info;
    while ((info = e.next_file(null)))
        if (/^blur-\d+\.png$/.test(info.get_name()))
            Gio.File.new_for_path(`${DIR}/${info.get_name()}`).delete(null);
    regenerate();
}

function disable() {
    Main.deskletContainer.actor.disconnect(addSignal);
    bgSettings.disconnect(bgSignal);
    tracked.forEach(([a, id]) => { try { a.disconnect(id); a.set_style(null); } catch (e) {} });
    tracked = [];
}
