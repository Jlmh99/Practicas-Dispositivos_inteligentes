# Ícono de wearable_app

Cerebro estilizado `#3A3AFF` sobre fondo `#F4F6F9`.

- `brain.svg` — fuente vectorial de referencia (200×200), útil para editar el
  diseño o regenerar los PNG con un rasterizador SVG.
- `ic_launcher_preview.png` / `ic_launcher_foreground_preview.png` — vistas
  previas de 1024×1024 generadas por el script.

## Cómo se generaron los PNG reales

En esta máquina no había ningún rasterizador de SVG disponible (sin
`cairosvg`, sin `rsvg-convert`, sin Inkscape), así que los PNG que sí se
commitean en `android/app/src/main/res/mipmap-*/` se generaron dibujando el
mismo diseño directamente con Pillow a 1024×1024 y reescalando con LANCZOS a
cada densidad — ver `../../tool/generate_icon.py`. Para regenerarlos:

```bash
cd wearable_app
python tool/generate_icon.py
```

## Alternativa: rasterizar brain.svg directamente

Si en otra máquina sí hay `rsvg-convert` disponible, este comando produce un
PNG equivalente por densidad (ejemplo para xxxhdpi, 192×192):

```bash
rsvg-convert -w 192 -h 192 assets/icon/brain.svg \
  -o android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
```

Repetir para mdpi (48), hdpi (72), xhdpi (96), xxhdpi (144), xxxhdpi (192).
Para el icono adaptativo (`ic_launcher_foreground.png`), usar el mismo
comando pero exportando solo el grupo del cerebro (sin el `<rect>` de fondo)
a `108/48` veces el tamaño legacy de cada densidad, y dejar el fondo como el
color sólido `@color/ic_launcher_background` definido en
`android/app/src/main/res/values/colors.xml` (ya wireado en
`mipmap-anydpi-v26/ic_launcher.xml`).
