# DEV 0.1.3 — Nivel digital de dos ejes (Core Motion)

**Fecha:** 2026-10-25 · **Estado: lectura de nivel confirmada por capturas del usuario a las 23:43; calibración, regresiones y tests pendientes**.
**Alcance:** asistencia visual experimental al fotografiar soportes **horizontales**. No se ha implementado aún análisis de la perspectiva de un soporte inclinado ni nivelado respecto al papel.

## Implementación técnica

- `LevelMath.swift`: conversión pura del vector de gravedad a inclinaciones X/Y en grados. Se normaliza el vector y se utiliza `atan2(gx, -gz)` / `atan2(gy, -gz)`. Se rechazan muestras no finitas, incoherentes y pantalla boca abajo o móvil vertical.
- `LevelMotionModel.swift`: `CMMotionManager.startDeviceMotionUpdates(to:withHandler:)` en cola `OperationQueue` con **20 Hz** como objetivo experimental. Filtrado exponencial de primer orden (alfa 0,25), publicación al hilo principal, defensa frente a callbacks antiguos tras salir de la pantalla y aviso por error del sensor. **No almacena ni transmite muestras**.
- `LevelOverlay.swift`: burbuja virtual de dos ejes, valores X/Y en grados y señal visual de tolerancia provisional.
- `ContentView.swift`: superposición durante vista de cámara; detener el sensor al revisar la fotografía, ir al fondo o desaparecer la pantalla. No se altera el pipeline de captura JPEG de DEV 0.1.2.
- `project.pbxproj`: versión `0.1.3`, build `4`; explicación `NSMotionUsageDescription` añadida a las configuraciones Debug y Release.
- `LevelMathTests.swift`: pruebas Swift Testing preparadas para postura horizontal, ángulos de signo positivo y negativo, umbral experimental, postura invertida/vertical y valores inválidos; **aún sin ejecutar**.

## Limitaciones conocidas

1. **Horizonte ≠ superficie.** El sensor describe la orientación del teléfono respecto a la gravedad, NO la normal del papel/cuadro. En un soporte inclinado no se puede afirmar perpendicularidad.
2. **Tolerancia ±2° es un valor inicial de prototipo**, no calibración certificada, garantía de foco ni validación de captura óptima. Deberá revisarse con datos.
3. Ejes X e Y son **ejes físicos del teléfono**, no nombres absolutos de izquierda/derecha de la interfaz en rotaciones. Para la primera prueba usar orientación vertical (portrait), pantalla mirando arriba, lente trasera hacia el soporte horizontal. Falta validar la presentación en landscape.
4. Puede haber pequeños sesgos del sensor o de la carcasa. Hace falta un patrón/plano horizontal de referencia, soporte estable y repetición para evaluar desviación.
5. Con la pantalla hacia abajo o dispositivo casi vertical NO aparece estado verde; se pide recolocar la pantalla. El nivel no funciona en simulador sin sensores adecuados.
6. La burbuja se suaviza ligeramente; observar si introduce retraso o vibración. Comprobar que 20 Hz no produce degradación perceptible de cámara, batería o CPU.
7. La cámara sigue guardando su JPEG intacto, no se incrustan datos de nivel en la foto.

## Protocolo de prueba en iPhone

- [ ] `git pull --ff-only` en `~/Developer/Fielens`; comprobar `git status -sb`.
- [ ] Xcode con iPhone físico como destino: `⌘B`; registrar Build Succeeded o el error exacto.
- [ ] `⌘R`; cámara operativa y panel NIVEL DIGITAL visible; comprobar autorización/consentimiento de movimiento si aparece.
- [ ] Colocar el móvil con pantalla mirando hacia arriba sobre una mesa nivelada. Ángulos X/Y cerca de 0; observar cuánto fluctúan en 10 segundos. Registrar resultados observados, **sin presuponer precisión**.
- [ ] Inclinar unos grados a cada lado y hacia delante/detrás: las lecturas deben cambiar de signo/dirección de forma coherente. Registrar si la burbuja se desplaza físicamente a la zona alta.
- [ ] Confirmar verde solo cuando ambos valores están dentro de la tolerancia experimental de 2°; en ángulos superiores debe ser naranja.
- [ ] Pantalla mirando hacia abajo y móvil vertical: ningún estado verde falso; se debe mostrar «Orienta la pantalla hacia arriba».
- [ ] Fotografiar una hoja sin datos personales sobre mesa horizontal; confirmar que la captura sigue ofreciendo la resolución original y que Repetir/Compartir funcionan.
- [ ] En la pantalla de revisión el nivel no debe seguir mostrando ni leyendo muestras; al pulsar Repetir debe reactivarse.
- [ ] Ir al inicio del iPhone y regresar: cámara y nivel deben recuperarse sin quedarse bloqueados. Comprobar varias repeticiones.
- [ ] Probar orientación horizontal de la UI y anotar si los ejes de pantalla resultan confusos. **No considerar paisaje validado sin inspección.**
- [ ] Xcode `Product → Test` (`⌘U`), anotar resultado de `LevelMathTests` y `OriginalPhotoTests`.
- [ ] Registrar dispositivo, iOS, hora, commit, ángulos observados, incidencias y regresiones en `docs/DEVELOPMENT_LOG.md`.

## Puerta para siguiente fase

No marcar H-009 como «funciona» ni desarrollar auto-disparo ligado al nivel hasta comprobar **compilación**, **movimiento correcto**, **no verde falso en poses no válidas** y que las fotografías siguen funcionando. La validación rigurosa de exactitud geométrica respecto al papel requiere un experimento posterior de visión computacional.

## Referencias de implementación

- Apple Core Motion CMMotionManager: https://developer.apple.com/documentation/coremotion/cmmotionmanager
- Apple CMDeviceMotion gravedad: https://developer.apple.com/documentation/coremotion/cmdevicemotion/gravity
- Apple uso de movimiento NSMotionUsageDescription: https://developer.apple.com/documentation/bundleresources/information-property-list/nsmotionusagedescription


## Primer ensayo real — 2026-10-25 23:41

| Muestra | X | Y | Interfaz |
| --- | ---: | ---: | --- |
| A | −0,2° | −0,2° | Verde |
| B | −0,1° | −0,4° | Verde |

Las muestras son coherentes con una pose cercana a horizontal, **pero el máximo observado de 0,4° no es error de precisión verificado**. El módulo de cámara sobresale de la trasera; el usuario apoyó el móvil al borde de la mesa. Se debe mejorar la referencia antes de calibrar o tocar umbrales.

**Banco de pruebas recomendado:** soporte rígido con hueco bajo cámaras (o apoyos paralelos idénticos bajo ambos lados que dejen las lentes libres), superficie verificada con un nivel externo, prueba de quietud durante 10 s y luego inclinaciones controladas en ambos ejes. No tomar el propio Fielens como patrón de referencia.

**Preview por comprobar:** ambas capturas muestran fondo de cámara negro pese a «Cámara activa». Puede ser la escena oscura o una obstrucción durante la prueba; antes de afirmar regresión, apuntar a una hoja muy iluminada y comprobar imagen en directo.

- [x] DEV 0.1.3 instalada/ejecutada en iPhone, nivel visible y muestras X/Y reportadas.
- [x] Estado verde coherente con lecturas dentro de ±2°.
- [ ] Muestreo estable sobre referencia conocida, prueba de signos y poses inválidas.
- [ ] Vista previa sobre hoja iluminada, disparo/repetición/compartir.
- [ ] Salida/retorno, giro de pantalla y tests automáticos.

## Aclaración posterior del creador — 2026-10-25 23:45

El fondo negro de ambas capturas correspondía a una prueba de noche y sin iluminación. Según confirma el creador, **no fue un fallo de la cámara**. La sospecha de regresión de la vista previa queda descartada para estas capturas. Continúan pendientes las pruebas generales de cámara y estabilidad, sin incidencia específica abierta por la imagen negra.
