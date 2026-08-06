// Navegación D-pad para una grilla de 2 columnas (2×2 en este proyecto).
// El índice de foco vive en una variable del módulo (`_indice`), nunca se
// deriva leyendo el DOM. La lógica de límites es explícita: al llegar al
// borde de la grilla el foco se queda quieto, nunca "envuelve" ni se rompe.

const COLUMNAS = 2;

// keyCodes de control remoto de Smart TV, además de los `event.key`
// estándar de teclado (ArrowUp/Down/Left/Right, Enter) que ya llegan solos.
const KEYCODE_OK = 13;
const KEYCODE_ARRIBA = 38;
const KEYCODE_ABAJO = 40;
const KEYCODE_IZQUIERDA = 37;
const KEYCODE_DERECHA = 39;
const KEYCODES_ATRAS = [8, 461];

export class DpadNavigator {
  /**
   * @param {Object} opciones
   * @param {() => number} opciones.contarItems Cuántas tarjetas hay ahora.
   * @param {(indice: number) => void} opciones.onFoco Se llama al mover el foco.
   * @param {(indice: number) => void} opciones.onSeleccionar Enter/OK.
   * @param {() => void} [opciones.onAtras] Tecla "back" del control remoto.
   */
  constructor({ contarItems, onFoco, onSeleccionar, onAtras }) {
    this._contarItems = contarItems;
    this._onFoco = onFoco;
    this._onSeleccionar = onSeleccionar;
    this._onAtras = onAtras;
    this._indice = 0;
    this._manejarTecla = this._manejarTecla.bind(this);
  }

  activar() {
    document.addEventListener('keydown', this._manejarTecla);
    this._onFoco(this._indice);
  }

  desactivar() {
    document.removeEventListener('keydown', this._manejarTecla);
  }

  indiceActual() {
    return this._indice;
  }

  /** Por si la lista de tarjetas cambia (ej. onSnapshot) y el índice actual
   * ya no existe — lo reacomoda al último válido. */
  reajustar() {
    const total = this._contarItems();
    if (total <= 0) return;
    if (this._indice >= total) this._indice = total - 1;
    this._onFoco(this._indice);
  }

  _manejarTecla(evento) {
    const total = this._contarItems();
    if (total <= 0) return;

    const codigo = evento.keyCode;
    const tecla = evento.key;

    if (tecla === 'ArrowUp' || codigo === KEYCODE_ARRIBA) {
      this._mover(-COLUMNAS, total);
      evento.preventDefault();
    } else if (tecla === 'ArrowDown' || codigo === KEYCODE_ABAJO) {
      this._mover(COLUMNAS, total);
      evento.preventDefault();
    } else if (tecla === 'ArrowLeft' || codigo === KEYCODE_IZQUIERDA) {
      this._moverHorizontal(-1, total);
      evento.preventDefault();
    } else if (tecla === 'ArrowRight' || codigo === KEYCODE_DERECHA) {
      this._moverHorizontal(1, total);
      evento.preventDefault();
    } else if (tecla === 'Enter' || tecla === 'OK' || codigo === KEYCODE_OK) {
      this._onSeleccionar(this._indice);
      evento.preventDefault();
    } else if (KEYCODES_ATRAS.includes(codigo) || tecla === 'Backspace') {
      if (this._onAtras) {
        this._onAtras();
        evento.preventDefault();
      }
    }
  }

  // Arriba/abajo: si el destino cae fuera de [0, total) el foco NO se mueve.
  _mover(delta, total) {
    const destino = this._indice + delta;
    if (destino < 0 || destino >= total) return;
    this._indice = destino;
    this._onFoco(this._indice);
  }

  // Izquierda/derecha: además de no salirse de [0, total), nunca cruza el
  // límite de columna (col 0 no va a la izquierda, última col no va a la derecha).
  _moverHorizontal(delta, total) {
    const columnaActual = this._indice % COLUMNAS;
    const columnaDestino = columnaActual + delta;
    if (columnaDestino < 0 || columnaDestino >= COLUMNAS) return;

    const destino = this._indice + delta;
    if (destino < 0 || destino >= total) return;

    this._indice = destino;
    this._onFoco(this._indice);
  }
}
