# DEV 0.1.7 — Nivel gravitatorio compacto

**Fecha:** 2026-10-26.
**Motivo:** en la captura de campo DEV 0.1.6, el panel central grande del nivel y los controles tapaban parte del documento que Vision había seleccionado.

## Implementación

- `LevelOverlay.swift` muestra de entrada una barra compacta con pequeña burbuja, grados X/Y y advertencia permanente «Gravedad · No indica perpendicularidad al objeto».
- El usuario puede tocar la barra para desplegar el panel de nivel ampliado y volver a tocar para contraerlo; la acción está descrita para accesibilidad.
- `ContentView.swift` coloca el nivel bajo el encabezado, dejando la zona central de fotografía más despejada. Se mantienen botones inferiores y selección de calidad.
- No se cambian `LevelMath.swift` ni `LevelMotionModel.swift`: la física, filtro y umbral de ±2° continúan experimentales. Nunca equivale a perpendicularidad respecto a un objeto físico inclinado.
- Versión 0.1.7, build 8; después DEV 0.1.8 mantiene esta mejora y añade arreglo táctil.

## QA pendiente en iPhone

- [ ] Barra compacta visible sin tapar contorno principal.
- [ ] Tocar barra expande y contrae sin interferir con visor, disparador ni Buscar contorno.
- [ ] Lectura X/Y cambia al mover móvil, mismo estado y señal que antes; no confundir verde con perpendicularidad.
- [ ] Se puede fotografiar/seleccionar superficie usando la región despejada de pantalla, con cámara a resolución original disponible.
- [ ] Accesibilidad con lector de pantalla y tamaños de texto ampliados.
- [ ] Estabilidad de vista al suspender/volver y al revisar y repetir.

**Estado:** implementado; comprobación física no recibida. La precisión de selección de contornos se evalúa aparte en [DEV 0.1.8](DEV_0.1.8_TOUCH_PRECISION.md).
