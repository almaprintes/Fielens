# DEV 0.1.5 — Resolución real del resultado fotográfico

**Fecha:** 2026-10-26.
**Estado:** código implementado en main; CI y prueba física pendientes de registrar.
**Incidencia motivadora:** 08:05. El creador seleccionó «Ligera» antes de tomar una foto y la pantalla posterior mostró 48,77 MP. La interfaz de DEV 0.1.4 mostraba siempre propiedades del JPEG original de sensor, aunque ya admitía derivar una copia ligera solamente al pulsar Compartir. Resultaba contrario a la expectativa del usuario.

## Comportamiento objetivo

- Seleccionando **Ligera**, la revisión mostrará el JPEG reducido de hasta 1600 píxeles de lado mayor (~1,92 MP con relación 4:3), con **dimensiones y peso calculados del archivo existente**, no de una fórmula esperada.
- **Compartir**: máximo 2400 píxeles de lado mayor (~4,32 MP si 4:3).
- **Detalle**: máximo 4000 píxeles (~12 MP si 4:3).
- **Original**: archivo JPEG inalterado de cámara; en prueba anterior en este iPhone, 8064 × 6048 píxeles = 48,77 MP.
- El usuario puede elegir la resolución antes del disparo, y modificarla tras capturar sin repetir. La pantalla de revisión recalcula y vuelve a mostrar **el archivo realmente seleccionado**.
- La hoja nativa envía **exactamente el mismo archivo JPEG que se visualiza** y cuyos metadatos se muestran. No hay una segunda recompresión en Fielens al compartir.
- En caso de fallo al preparar la versión elegida se muestra error; no sustituir silenciosamente una salida Ligera por el original de 48 MP.

## Decisión provisional sobre captura frente a salida

La cámara **continúa capturando temporalmente a resolución nativa**; en DEV 0.1.5, el resultado visible y compartido tiene la resolución escogida. La captura fuente se conserva solo en el directorio temporal privado durante esa sesión para que cambiar la selección no destruya datos; al repetir la foto se borra la fuente.

Esto **no implementa aún adquisición nativa a 2, 4 o 12 MP en AVCapturePhotoOutput**. Esa optimización futura exige evaluar resoluciones soportadas, coste de captura/procesado, velocidad y nitidez antes de hacerla. No se afirma ahorro de memoria en el disparo; sí archivos de salida reducidos.

## Archivos cambiados

- `PhotoExportService.swift`: `PreparedPhoto` contiene URL, preset, píxeles y bytes **leídos del archivo preparado**. `prepareForReview` no transforma Original; para otros perfiles usa ImageIO, sin copiar EXIF fuente.
- `ContentView.swift`: al llegar foto o cambiar preset, tarea de trabajo fuera del hilo principal prepara el resultado; revisión muestra el JPEG real con sus metadatos. Se evita pintar el original mientras se prepara un derivado; el botón Compartir permanece deshabilitado hasta que la selección esté preparada. Se descarta copia temporal anterior al cambiar de perfil o pulsar Repetir.
- `PhotoExportTests.swift`: verificación de resultado Ligera real, 1600 × 1200 desde foto de prueba 2000 × 1500, peso de bytes consistente con el fichero, fuente idéntica, y opción Original sin modificación.
- `project.pbxproj`: versión DEV 0.1.5, build 6.

## QA requerido

- [ ] `main` en Mac sincronizada con `git pull --ff-only`, estado limpio salvo cambios conocidos.
- [ ] GitHub Actions: compilación Xcode 26.6 verde de un SHA que incluya el cambio y tests del simulador verdes. Confirmar SHA.
- [ ] Xcode en iPhone: elegir Ligera **antes** de disparar, hacer foto de hoja ficticia; **la revisión ha de indicar ~1600 × 1200, 1,92 MP** para la imagen 4:3 de este iPhone y su peso real, no 48,77 MP.
- [ ] Desde esa misma foto elegir Compartir: debe actualizar dimensiones a ~2400 × 1800 (4,32 MP), peso del archivo y previsualización sin volver a cámara.
- [ ] Elegir Detalle: ~4000 × 3000 (12 MP); elegir Original: 8064 × 6048 (48,77 MP) si la captura fuente tiene esa resolución.
- [ ] Probar todas las opciones tras disparar sin cierres, congelaciones ni imágenes en negro.
- [ ] Pulsar Compartir con Ligera y guardar en Archivos: verificar que las dimensiones y el peso coinciden con **la revisión inmediatamente anterior**. Repetir con Original y otra calidad.
- [ ] Cambiar varias veces Ligera → Original → Compartir → Ligera; las copias temporales antiguas deben limpiarse y el original seguir intacto.
- [ ] Repetir desde cada preset, volver a cámara y capturar otra foto.
- [ ] Pruebas con dispositivo girado y EXIF orientado, privacidad GPS en copias y legibilidad de texto fino.
- [ ] Medir coste temporal desde disparo a vista utilizable, especialmente a 48 MP.

## Reglas de producto

La elección antes del disparo debe afectar la fotografía que el usuario **ve y obtiene**, aunque internamente se conserve temporalmente una fuente maestra. Nunca publicar una app en que elegir «Ligera» termine visualmente con un resultado de 48,77 MP sin explicación. En Fielens, claridad de UX y fidelidad al archivo están por encima de la implementación interna.

**Sin datos de DNI reales ni fotos personales en el repositorio público.**
