"""Genera los iconos 192x192 y 512x512 de manifest.json: cerebro estilizado
#3A3AFF sobre fondo #0F0F1A (el mismo azul de marca, pero sobre el fondo
oscuro de la TV, que es el `background_color` declarado en el manifest).

Mismo enfoque que wearable_app/tool/generate_icon.py: se dibuja directo con
Pillow (sin rasterizar el SVG hermano, assets/icons/icon.svg) porque esta
máquina no tiene cairosvg/rsvg-convert/Inkscape instalados. El contenido se
mantiene dentro del círculo "safe zone" del 80% central para que funcione
como icono `purpose: "any maskable"` sin que el sistema operativo recorte el
cerebro al aplicar su propia máscara (circular, squircle, etc.).

Uso:
    python tool/generate_icons.py
"""

from PIL import Image, ImageDraw
import os

AZUL = (0x3A, 0x3A, 0xFF, 255)
AZUL_PLIEGUE = (0x8A, 0x8A, 0xFF, 255)  # más claro que el fondo oscuro, no más oscuro
FONDO = (0x0F, 0x0F, 0x1A, 255)

MASTER = 1024
TAMANOS = [192, 512]


def _dibujar_cerebro(size: int, escala: float) -> Image.Image:
    """Cerebro centrado, escalado por `escala` (1.0 = ocupa la mayor parte
    del lienzo). Con escala más chica cabe dentro del safe-zone maskable."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = size / 2, size / 2

    def pt(x, y):
        # x,y en coordenadas normalizadas del diseño original (0..1, centrado en 0.5,0.5)
        return (cx + (x - 0.5) * size * escala, cy + (y - 0.5) * size * escala)

    def box(x0, y0, x1, y1):
        return [pt(x0, y0), pt(x1, y1)]

    draw.ellipse(box(0.20, 0.30, 0.80, 0.70), fill=AZUL)

    lobulos_x = [0.26, 0.37, 0.48, 0.59, 0.70]
    for i, lx in enumerate(lobulos_x):
        r = 0.085 if i % 2 == 0 else 0.10
        draw.ellipse(box(lx - r, 0.24 - r * 0.6, lx + r, 0.24 + r * 0.9), fill=AZUL)

    draw.ellipse(box(0.58, 0.60, 0.76, 0.80), fill=AZUL)
    draw.rounded_rectangle(box(0.62, 0.72, 0.70, 0.86), radius=size * 0.02 * escala, fill=AZUL)

    ancho_linea = max(2, int(size * 0.018 * escala))
    draw.line(
        [pt(0.50, 0.32), pt(0.49, 0.45), pt(0.51, 0.58), pt(0.50, 0.68)],
        fill=AZUL_PLIEGUE,
        width=ancho_linea,
        joint="curve",
    )
    ancho_pliegue = max(2, int(size * 0.014 * escala))
    draw.arc(box(0.24, 0.34, 0.46, 0.50), start=200, end=340, fill=AZUL_PLIEGUE, width=ancho_pliegue)
    draw.arc(box(0.26, 0.46, 0.46, 0.60), start=200, end=340, fill=AZUL_PLIEGUE, width=ancho_pliegue)
    draw.arc(box(0.54, 0.34, 0.74, 0.50), start=200, end=340, fill=AZUL_PLIEGUE, width=ancho_pliegue)
    draw.arc(box(0.54, 0.46, 0.72, 0.58), start=200, end=340, fill=AZUL_PLIEGUE, width=ancho_pliegue)

    return img


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    icons_dir = os.path.join(root, "assets", "icons")
    os.makedirs(icons_dir, exist_ok=True)

    fondo = Image.new("RGBA", (MASTER, MASTER), FONDO)
    # escala 0.72: dentro de la safe-zone maskable (círculo del 80% central)
    cerebro = _dibujar_cerebro(MASTER, escala=0.72)
    fondo.alpha_composite(cerebro)

    for tam in TAMANOS:
        salida = fondo.resize((tam, tam), Image.LANCZOS)
        ruta = os.path.join(icons_dir, f"icon-{tam}.png")
        salida.save(ruta)
        print("Generado", ruta)


if __name__ == "__main__":
    main()
