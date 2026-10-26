# DEV 0.1.11 — Superficies automáticas, sin pulsar «Buscar»

**Fecha:** 26 de octubre de 2026
**Origen:** retroalimentación directa del creador: sostener y apuntar el iPhone mientras toca «Buscar», «Otro» y «Ajustar esquinas» es poco práctico porque el móvil se mueve.
**Estado:** implementación en main; Xcode en la nube y pruebas del iPhone deben verificarse por commit. **No está aprobada aún en dispositivo.**

## Objetivo de experiencia

1. Abrir la cámara. Fielens comienza a buscar una superficie rectangular **automáticamente**, sin pulsar nada.
2. Cuando Apple Vision detecta un rectángulo grande y suficientemente central, se señala **solo ese** con contorno menta. Los candidatos secundarios no ensucian el visor.
3. Mientras el usuario encuadra a mano, Fielens repite análisis **con cadencia limitada** y estabiliza las esquinas; si reconoce el mismo cuadrilátero, conserva su identidad para evitar saltos innecesarios.
4. Si la superficie se pierde repetidamente, se borra el contorno. No persistir indefinidamente una indicación obsoleta.
5. El usuario puede fotografiar sin interacción adicional. **El disparador continúa siendo manual.** No se incluye auto-captura antes de tener mediciones fiables de foco, perspectiva y estabilidad.
6. En situaciones ambiguas, un **toque sobre el objetivo** o el discreto menú «…» permite corregir la selección. El editor de esquinas sigue disponible como excepción, sin imponerse.
7. Core Motion sigue midiendo el **nivel respecto a la gravedad**, no la perpendicularidad a cualquier soporte. El color menta del contorno NO significa geometría perfecta.

## Diseño técnico y rendimiento

- `AutomaticSurfaceTracker.swift` introduce selección por área, centralidad y confianza, correlación entre detecciones consecutivas por posición/tamaño, identificadores estables y suavizado moderado de las cuatro esquinas.
- `CameraViewModel.swift`: después de `AVCaptureSession.startRunning`, programa la siguiente petición Vision; **nunca más de una petición en curso**. Intervalo después de éxito ~550 ms, sin rectángulo ~850 ms, tras error ~1800 ms. El tiempo real entre análisis incluye además el coste de Vision, por lo que no prometemos 60 FPS para el contorno.
- Usa `SurfaceFrameSampler` ya disponible: delegado AVFoundation descarta los frames tardíos, ejecuta `VNDetectRectanglesRequest` únicamente cuando hay una petición y dispone de timeout para no bloquearse. La cámara/foto original no dependen de obtener un resultado.
- Cambios a segundo plano, revisión de foto, salida de cámara y permiso denegado paran o impiden los nuevos ciclos; las respuestas de la sesión anterior se invalidan por generación.
- Al editar esquinas se pausa el análisis; al salir se vuelve al seguimiento automático. Los ajustes manuales son una alternativa, no el flujo normal.
- En `CameraPreview.swift` se dibuja solo el contorno seleccionado, aunque todos los candidatos válidos siguen disponibles para detectar un toque corrector.
- Se conserva el selector de resolución de DEV 0.1.5 y la captura original no se recorta ni modifica con Vision.
- Test unitarios `AutomaticSurfaceTrackerTests.swift`: selección automática con elementos internos pequeños, ID estable con movimiento leve, preservar elección manual, descartar objetivos inválidos o desaparecidos y cambio a otro rectángulo.

## Riesgos conocidos

1. Vision requiere CPU y energía. La cadencia es experimental, no se ha medido consumo/calor/FPS en el iPhone del creador. Si se calienta o cae FPS, bajar frecuencia o combinar `VNTrackRectangleRequest` para seguimiento ligero con redetección periódica.
2. El contorno se actualiza en **saltos** cada análisis, con suavizado de posiciones; no existe seguimiento continuo de alta frecuencia. Este primer incremento busca comprobar UX y presupuesto de procesamiento.
3. Una cámara moviéndose bruscamente puede perder el objeto; el contorno se limpia tras dos análisis sin detección. La selección automática puede elegir una pantalla/carpeta/cuadro del fondo en vez del documento deseado; toque corrector como respaldo.
4. El tracker compara centro y área de cuadriláteros (sin semántica): no garantiza reconocimiento de personas, objetos volumétricos ni planos irregulares.
5. El nivel no calcula ángulo real respecto al soporte, y **todavía no hay disparo automático**. Hacerlo sin calibración podría generar fotografías sesgadas o ilegibles.
6. Los frames no se almacenan, suben ni envían a red. Repositorio público no debe contener documentos reales.

## Pruebas obligatorias

- [ ] Build Xcode 26.6 en GitHub Actions **del SHA final** y tests Swift en simulador pasan.
- [ ] `git status --short` y `git pull --ff-only` solo con estado local limpio; `⌘B` y `⌘R` en iPhone.
- [ ] Al abrir cámara no hace falta pulsar Buscar. Una hoja A4 sobre fondo contrastado recibe contorno menta sola, aunque la mano tiemble un poco.
- [ ] Mover suavemente iPhone a izquierda/derecha y adelante/atrás; comprobar que el contorno acompaña el papel sin saltar a otros objetos, con latencia razonable.
- [ ] Foto impresa dentro de hoja A4: revisar qué rectángulo se elige; tocar el otro como corrección y confirmar que no recupera el anterior en el siguiente ciclo.
- [ ] Quitar el papel; la marca debe desaparecer después de uno o dos ciclos, sin verde residual. Apuntar de nuevo: readquirir.
- [ ] Sombras, reflejos y fondos con rectángulos: registrar falsos positivos.
- [ ] Entrar al editor opcional y arrastrar una esquina sin que Vision la mueva; terminar edición y comprobar que vuelve el seguimiento.
- [ ] Hacer una foto en todas las condiciones; conservar el JPEG nativo (antes 8064 × 6048) y comprobar elección Ligera/Original en revisión.
- [ ] Regresar a cámara con Repetir; ir a inicio y reabrir; observar que no se multiplica el procesamiento ni se queda «Analizando…».
- [ ] Medir FPS perceptibles, tiempo entre actualizaciones, temperatura del iPhone y autonomía tras 5–10 minutos de escaneo. Comparar DEV 0.1.10.
- [ ] Comprobar orientación retrato y documentar limitaciones al girar a paisaje.

## Futuro: perpendicularidad y captura verdaderamente automáticas

Cuando la detección y el seguimiento sean fiables, estimar plano 3D respecto al eje óptico (con calibración y estimación de confianza), mostrar correcciones sin confundirlas con gravedad y evaluar disparo automático **optativo** solo tras asegurar foco, estabilidad y geometría. Hasta entonces no inventar un indicador de «perpendicular perfecto».

**Señal de calidad:** poder abrir la cámara, apuntar al documento, verlo resaltado sin pulsar ninguna herramienta y fotografiarlo normalmente. Esa es la prueba clave de esta versión.
