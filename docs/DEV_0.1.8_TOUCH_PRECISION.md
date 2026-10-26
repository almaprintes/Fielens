# DEV 0.1.8 — Selección táctil precisa del contorno mostrado

**Fecha:** 2026-10-26, después de las pruebas de 09:49–09:55.
**Estado:** código implementado en rama `main`. Compilación y tests CI pendientes de confirmación del SHA final; **todavía no verificado en el iPhone**.

## Informe del creador que motiva la iteración

El creador probó DEV 0.1.6 con una hoja sobre una mesa y envió dos capturas de pantalla. Vio contorno resaltado en verde menta, lectura del nivel X +0,9° / Y −5,1°, y una captura Ligera de **1200 × 1600 px, 1,92 MP, 345 KB**, conforme a la resolución solicitada. Reportó expresamente **«La detección al toque no es nada precisa»**.

No subir las imágenes compartidas al repositorio público ni transcribir datos impresos sobre la hoja.

## Diagnóstico técnico basado en código, no en suposiciones visuales

En DEV 0.1.6, `CameraPreview.didTapPreview` convertía la coordenada de pantalla con `AVCaptureVideoPreviewLayer.captureDevicePointConverted(fromLayerPoint:)` (origen superior izquierdo de imagen *sin rotar*) y luego aplicaba solo una inversión del eje Y para producir una posición Vision (imagen orientada `.right`). Esa equivalencia **no estaba demostrada**: Vision y AVFoundation tienen convenciones distintas de orientación, recorte y eje de coordenadas. Por separado, `CameraPreview.updateContours` proyectaba los vértices de Vision a capa. Esto podía provocar que el punto usado en selección **no coincidiera** con el mismo polígono que se veía dibujado. Apple distingue explícitamente ambos espacios: https://developer.apple.com/documentation/avfoundation/avcapturevideopreviewlayer/capturedevicepointconverted(fromlayerpoint:) y https://developer.apple.com/documentation/vision/vnrectangleobservation.

Además, `SurfaceSelector` original elegía siempre el **menor rectángulo** que contuviese el toque. Una hoja con etiquetas, cajas de texto o cuadriláteros detectados dentro podía seleccionar un recuadro interior en vez de la propia página.

## Corrección DEV 0.1.8

1. `SurfaceViewPoint` (origen superior izquierdo) y `SurfaceScreenPolygon` representan puntos y contornos en espacio **visual de la vista previa**, normalizado a sus dimensiones.
2. `CameraPreview` usa la transformación a coordenadas de pantalla **una única vez** para dibujar y probar geometría de contornos. Los eventos de toque del usuario se normalizan desde la posición física en esa misma vista, sin convertirlos por una segunda cadena cámara↔Vision.
3. `SurfaceScreenSelector` decide pertenencia geométrica al cuadrilátero **visible**. Ante contornos anidados, prioriza el de mayor superficie visible, para evitar que un texto impreso robe la selección de la hoja. Es una política **provisional**: para elegir objetos anidados se ofrece «Otro» y habrá que mejorar la desambiguación en futuras pruebas.
4. Si el usuario toca antes de tener candidatos, se conserva la **posición en pantalla del toque original** junto con un ID de petición. Después de recibir la respuesta de Vision, UIKit compara esa posición contra los polígonos **ya proyectados** y notifica la selección a `CameraViewModel` de forma diferida, sin publicar cambios durante `updateUIView`.
5. `CameraViewModel` permite cambiar a otro candidato con botón «Otro» cuando hay varios, y descarta peticiones táctiles antiguas al salir o capturar.
6. Tests `SurfaceGeometryTests.swift`: panel mayor conteniendo caja de texto menor, toque fuera del polígono, trapezoide visible, polígonos degenerados/NaN.
7. App identificada como **DEV 0.1.8 build 9**. Se mantienen el nivel gravitatorio compacto y el sistema de resoluciones/captura original de DEV 0.1.7.

**Límite importante:** esta corrección garantiza que el toque se evalúa frente al **contorno dibujado**, pero **NO garantiza** todavía que el contorno visual coincida perfectamente con los bordes físicos de la hoja. La calibración Vision→preview, orientación retrato/paisaje, cambios por estabilización y la selección semántica de objetos irregulares siguen siendo experimentales. El contorno no confirma perpendicularidad 3D.

## Pruebas de aceptación

- [ ] GitHub Actions para el commit final: `Compile iOS without signing` y `Swift unit tests on iOS simulator` en verde.
- [ ] `git pull --ff-only`, Xcode `⌘B`, `⌘R` en el iPhone. La app debe mostrar DEV 0.1.8.
- [ ] Poner hoja clara sobre fondo oscuro con buena iluminación. Pulsar Buscar contorno y tocar **centro de la página**: debe seleccionar la hoja completa, no una caja de texto interior.
- [ ] Tocar distintas zonas de la hoja **visibles y sin controles encima** (centro, cuatro cuadrantes): comprobar que el resultado sigue correspondiendo al polígono visible.
- [ ] Tocar claramente fuera de la hoja: no debe afirmar que la página ha sido seleccionada. Puede pedir un escaneo nuevo; verificar el estado.
- [ ] Tras Repetir o abrir cámara sin buscar previamente, **un solo toque** sobre la hoja debe iniciar análisis y seleccionar el polígono correspondiente al toque original (sin exigir segundo toque).
- [ ] Colocar dos rectángulos separados en encuadre; tocar primero uno y luego otro, verificando el contorno correcto.
- [ ] Con varios rectángulos superpuestos, comprobar botón **Otro** y decidir si la política «mayor primero» es suficientemente natural.
- [ ] Comparar precisión del contorno dibujado con cuatro esquinas reales de una hoja A4 marcada; fotografiar la pantalla sin subir datos personales y medir desplazamiento visual antes de declarar calibración.
- [ ] Mover el teléfono: el contorno de un frame anterior no sigue el objeto; repetir Buscar contorno. No confundir la selección acertada con seguimiento continuo.
- [ ] Regresión: nivel gravitatorio compacto, foto Ligera de 1,92 MP, cambio a Original de ~48,77 MP cuando la fuente lo permita, compartir desde el mismo fichero JPEG, Repetir y segundo plano.
- [ ] Medir tasa de falsos toques en al menos 10 intentos con fondo/textos variados. Documentar cualquier error con su contexto, sin imágenes sensibles.

## No cerrar todavía

El éxito requiere observación en iPhone, no solo compilación en macOS. No introducir automáticamente recorte/corrección de perspectiva ni estimación angular 3D hasta que se controle la selección táctil. Si Vision localiza erróneamente los bordes, tratarlo como problema separado de detección visual y revisar orientación/intrínsecos.
