#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

f="$1"
{
  echo '<style>* {background-color: #000;}</style><h1 style="color: #fff">Wait a bit...</h1><form style="opacity: 0;" id="f" method="POST" enctype="multipart/form-data" action="https://lens.google.com/v3/upload"><input type="file" name="encoded_image" id="i"></form><script>'
  echo -n 'const b64="'; base64 -w0 "$f"; echo '";'
  echo 'const bin=Uint8Array.from(atob(b64),c=>c.charCodeAt(0));const dt=new DataTransfer();dt.items.add(new File([bin],"image.png",{type:"image/png"}));document.getElementById("i").files=dt.files;document.getElementById("f").submit();</script>'
} > /tmp/lens.html
$SCRIPT_DIR/webview file:///tmp/lens.html
