"""Genera el icono propio de wearable_app: un cerebro estilizado #3A3AFF
sobre fondo #F4F6F9.

No se usa una librería de rasterizado de SVG (no había ninguna disponible en
esta máquina: sin cairosvg, sin rsvg-convert, sin Inkscape). En su lugar el
cerebro se dibuja directamente con Pillow (unión de elipses + arcos para los
pliegues) a alta resolución y se reescala con LANCZOS a cada densidad, lo que
da el mismo resultado visual que rasterizar el SVG hermano
(assets/icon/brain.svg) pero sin depender de herramientas externas.

Uso:
    python tool/generate_icon.py

Requiere Pillow (`pip install pillow`).
"""

from PIL import Image, ImageDraw
import os

AZUL = (0x3A, 0x3A, 0xFF, 255)
AZUL_PLIEGUE = (0x26, 0x26, 0xB8, 255)
FONDO = (0xF4, 0xF6, 0xF9, 255)

MASTER = 1024  # lienzo de trabajo de alta resolución

# tamaño legacy (px) por densidad, y factor del icono adaptativo (108dp) sobre 48dp
DENSIDADES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}


def _dibujar_cerebro(size: int) -> Image.Image:
    """Devuelve el cerebro solo (RGBA, fondo transparente), centrado y
    ocupando ~66% del lienzo (zona segura de un adaptive icon)."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    def pt(x, y):
        return (x * size, y * size)

    def box(x0, y0, x1, y1):
        return [pt(x0, y0), pt(x1, y1)]

    # Masa principal (óvalo horizontal) — dentro de la zona segura 17%-83%.
    draw.ellipse(box(0.20, 0.30, 0.80, 0.70), fill=AZUL)

    # Lóbulos superiores: bultos que dan la silueta ondulada característica.
    lobulos_x = [0.26, 0.37, 0.48, 0.59, 0.70]
    for i, cx in enumerate(lobulos_x):
        r = 0.085 if i % 2 == 0 else 0.10
        draw.ellipse(box(cx - r, 0.24 - r * 0.6, cx + r, 0.24 + r * 0.9), fill=AZUL)

    # Cerebelo / tallo cerebral: bulto inferior derecho.
    draw.ellipse(box(0.58, 0.60, 0.76, 0.80), fill=AZUL)
    draw.rounded_rectangle(box(0.62, 0.72, 0.70, 0.86), radius=size * 0.02, fill=AZUL)

    # Surco central (separa hemisferios).
    draw.line(
        [pt(0.50, 0.32), pt(0.49, 0.45), pt(0.51, 0.58), pt(0.50, 0.68)],
        fill=AZUL_PLIEGUE,
        width=max(2, int(size * 0.018)),
        joint="curve",
    )

    # Pliegues (gyri): un par de arcos por hemisferio.
    ancho_pliegue = max(2, int(size * 0.014))
    draw.arc(box(0.24, 0.34, 0.46, 0.50), start=200, end=340, fill=AZUL_PLIEGUE, width=ancho_pliegue)
    draw.arc(box(0.26, 0.46, 0.46, 0.60), start=200, end=340, fill=AZUL_PLIEGUE, width=ancho_pliegue)
    draw.arc(box(0.54, 0.34, 0.74, 0.50), start=200, end=340, fill=AZUL_PLIEGUE, width=ancho_pliegue)
    draw.arc(box(0.54, 0.46, 0.72, 0.58), start=200, end=340, fill=AZUL_PLIEGUE, width=ancho_pliegue)

    return img


def _icono_legacy(cerebro: Image.Image, size: int, redondo: bool) -> Image.Image:
    fondo = Image.new("RGBA", (MASTER, MASTER), FONDO)
    fondo.alpha_composite(cerebro)
    if redondo:
        mask = Image.new("L", (MASTER, MASTER), 0)
        ImageDraw.Draw(mask).ellipse([0, 0, MASTER, MASTER], fill=255)
        fondo.putalpha(mask)
    return fondo.resize((size, size), Image.LANCZOS)


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    res = os.path.join(root, "android", "app", "src", "main", "res")

    cerebro_master = _dibujar_cerebro(MASTER)
    legacy_master = _icono_legacy(cerebro_master, MASTER, redondo=False)
    round_master = _icono_legacy(cerebro_master, MASTER, redondo=True)

    # Fuente del SVG (assets/icon/) — copia de referencia en alta resolución.
    icon_assets = os.path.join(root, "assets", "icon")
    os.makedirs(icon_assets, exist_ok=True)
    legacy_master.save(os.path.join(icon_assets, "ic_launcher_preview.png"))
    cerebro_master.save(os.path.join(icon_assets, "ic_launcher_foreground_preview.png"))

    for densidad, size_legacy in DENSIDADES.items():
        carpeta = os.path.join(res, f"mipmap-{densidad}")
        os.makedirs(carpeta, exist_ok=True)

        legacy_master.resize((size_legacy, size_legacy), Image.LANCZOS).save(
            os.path.join(carpeta, "ic_launcher.png")
        )
        round_master.resize((size_legacy, size_legacy), Image.LANCZOS).save(
            os.path.join(carpeta, "ic_launcher_round.png")
        )

        # Icono adaptativo: foreground a 108dp equivalente (2.25x el legacy 48dp).
        size_adaptive = round(size_legacy * (108 / 48))
        cerebro_master.resize((size_adaptive, size_adaptive), Image.LANCZOS).save(
            os.path.join(carpeta, "ic_launcher_foreground.png")
        )

    print("Iconos generados en", res)


if __name__ == "__main__":
    main()
