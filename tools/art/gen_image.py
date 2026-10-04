"""Generate one image with OpenAI gpt-image-1 (D50). Standard library only.

The API key is read from the OPENAI_API_KEY environment variable and is never
written anywhere. Usage:
    python tools/art/gen_image.py --out <file.png> --prompt "..." [--style tools/art/style_block.txt]
        [--size 1024x1024] [--quality medium] [--n 1] [--opaque] [--image ref.png ...]
With --image, the reference image(s) are edited instead (same character, new pose/version).
With --n > 1 the files are named <file>_1.png, <file>_2.png, ...
"""

import argparse
import base64
import json
import os
import sys
import urllib.error
import urllib.request
import uuid

API_URL = "https://api.openai.com/v1/images/generations"
EDIT_URL = "https://api.openai.com/v1/images/edits"


def _multipart(fields: dict, files: list) -> tuple:
    """Encodes form fields and (name, path) files as multipart/form-data."""
    boundary = "----gen-image-%s" % uuid.uuid4().hex
    crlf = "\r\n"
    parts = []
    for name, value in fields.items():
        parts.append(("--" + boundary + crlf + 'Content-Disposition: form-data; name="%s"' % name
                + crlf + crlf + str(value) + crlf).encode("utf-8"))
    for name, path in files:
        with open(path, "rb") as f:
            data = f.read()
        header = ("--" + boundary + crlf
                + 'Content-Disposition: form-data; name="%s"; filename="%s"' % (name, os.path.basename(path))
                + crlf + "Content-Type: image/png" + crlf + crlf)
        parts.append(header.encode("utf-8") + data + crlf.encode("utf-8"))
    parts.append(("--" + boundary + "--" + crlf).encode("utf-8"))
    return b"".join(parts), "multipart/form-data; boundary=" + boundary


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", required=True)
    parser.add_argument("--prompt", required=True)
    parser.add_argument("--style", help="text file prepended to the prompt (shared style block)")
    parser.add_argument("--size", default="1024x1024")
    parser.add_argument("--quality", default="medium", choices=["low", "medium", "high"])
    parser.add_argument("--n", type=int, default=1)
    parser.add_argument("--opaque", action="store_true", help="keep a background (default: transparent)")
    parser.add_argument("--image", nargs="+", help="reference image(s) to edit (keeps the character's design)")
    parser.add_argument("--mask", help="with --image: PNG, same size as the first image, transparent where it may change")
    args = parser.parse_args()

    key = os.environ.get("OPENAI_API_KEY")
    if not key:
        print("OPENAI_API_KEY is not set", file=sys.stderr)
        return 1

    prompt = args.prompt
    if args.style:
        with open(args.style, encoding="utf-8") as f:
            prompt = f.read().strip() + "\n\n" + prompt

    body = {
        "model": "gpt-image-1",
        "prompt": prompt,
        "size": args.size,
        "quality": args.quality,
        "n": args.n,
        "output_format": "png",
        "background": "opaque" if args.opaque else "transparent",
    }
    if args.image:
        body["input_fidelity"] = "high"
        files = [("image[]", path) for path in args.image]
        if args.mask:
            files.append(("mask", args.mask))
        data, content_type = _multipart(body, files)
        url = EDIT_URL
    else:
        data, content_type = json.dumps(body).encode("utf-8"), "application/json"
        url = API_URL
    request = urllib.request.Request(
        url, data=data, headers={"Authorization": "Bearer " + key, "Content-Type": content_type})
    try:
        with urllib.request.urlopen(request, timeout=300) as response:
            result = json.load(response)
    except urllib.error.HTTPError as error:
        print("HTTP %d: %s" % (error.code, error.read().decode("utf-8", "replace")), file=sys.stderr)
        return 1

    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    base, ext = os.path.splitext(args.out)
    for i, item in enumerate(result["data"]):
        path = args.out if args.n == 1 else "%s_%d%s" % (base, i + 1, ext or ".png")
        with open(path, "wb") as f:
            f.write(base64.b64decode(item["b64_json"]))
        print(path)
    usage = result.get("usage")
    if usage:
        print("tokens:", usage.get("total_tokens"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
