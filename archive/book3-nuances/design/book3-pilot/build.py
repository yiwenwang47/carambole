"""Inline shots/*.jpg into nuances-pilot.src.html -> nuances-pilot.html.

Edit the .src.html (placeholders like @@word@@), then run:
    python3 design/book3-pilot/build.py
"""
import base64
import pathlib

HERE = pathlib.Path(__file__).parent


def main() -> None:
    html = (HERE / "nuances-pilot.src.html").read_text()
    for shot in sorted((HERE / "shots").glob("*.jpg")):
        data = base64.b64encode(shot.read_bytes()).decode()
        html = html.replace(f"@@{shot.stem}@@", f"data:image/jpeg;base64,{data}")
    assert "@@" not in html, "unreplaced image placeholder"
    (HERE / "nuances-pilot.html").write_text(html)


if __name__ == "__main__":
    main()
