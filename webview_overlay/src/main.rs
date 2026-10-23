use gtk::gdk::keys::constants::Escape;
use gtk::{glib, prelude::*};
use gtk_layer_shell::{Edge, Layer, LayerShell};
use std::env;
use webkit2gtk::{CookieManagerExt, SettingsExt, WebContext, WebContextExt, WebView, WebViewExt};

fn main() {
    unsafe {
        std::env::set_var("__NV_DISABLE_EXPLICIT_SYNC", "1");
    }

    glib::set_prgname(Some("cts-webview"));

    let args: Vec<String> = env::args().collect();
    let url = args.get(1).expect("Pass url as the argument");

    gtk::init().expect("Couldn't initialize GTK");

    let window = gtk::Window::new(gtk::WindowType::Toplevel);
    window.set_title("Wayland WebView Overlay");

    window.init_layer_shell();

    window.set_layer(Layer::Overlay);

    window.set_namespace("webview-overlay");

    window.set_anchor(Edge::Top, true);
    window.set_anchor(Edge::Bottom, true);
    window.set_width_request(800);
    window.set_anchor(Edge::Right, true);
    window.set_keyboard_interactivity(true);

    let context = WebContext::default().expect("Failed to get default WebContext");

    if let Some(cookie_manager) = context.cookie_manager() {
        let data_dir = glib::user_data_dir().join("cts-webview");
        std::fs::create_dir_all(&data_dir).ok();
        let cookie_file = data_dir.join("cookies.txt");

        cookie_manager.set_persistent_storage(
            cookie_file.to_str().unwrap(),
            webkit2gtk::CookiePersistentStorage::Text,
        );
        cookie_manager.set_accept_policy(webkit2gtk::CookieAcceptPolicy::Always);
    }

    window.connect_key_press_event(|_, event| {
        if event.keyval() == Escape {
            gtk::main_quit();
            glib::Propagation::Stop
        } else {
            glib::Propagation::Proceed
        }
    });

    let webview = WebView::with_context(&context);

    if let Some(settings) = WebViewExt::settings(&webview) {
        settings.set_user_agent(Some(
                "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
            ));
        settings.set_enable_javascript(true);
        settings.set_enable_html5_local_storage(true);
    }

    webview.load_uri(url);

    window.add(&webview);
    window.show_all();

    gtk::main();
}
