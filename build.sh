cd ./webview_overlay

cargo build --release

cp ./target/release/webview_overlay ../webview

cd ..
chmod +x ./webview
