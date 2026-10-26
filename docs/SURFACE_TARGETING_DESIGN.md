# Diseño EXP-002 — Selección de superficies y guía perpendicular

**Fecha:** 2026-10-25. **Estado:** diseño/arquitectura propuesta, aún sin orientación relativa al soporte calibrada. 
**Motivación:** el creador propone seleccionar con un toque el objeto a fotografiar y que la guía de inclinación se adapte a *ese objeto*, no a la gravedad.

## Experiencia deseada

1. Cámara en directo sin alterar el flujo actual de fotografía de alta resolución.
2. El usuario toca la hoja/foto/cuadro/objeto deseado. Si hay varios candidatos, el toque desambigua.
3. Fielens resalta el contorno detectado; permite corregir esquinas si falla. El usuario confirma selección y puede cambiar de objetivo.
4. Solo si se ha identificado un **plano verificable**, mostrar guía de orientación relativa al soporte; incluir corrección en ambos ejes y estabilidad. Etiquetas: «Detectando», «Contorno seleccionado», «Perspectiva estimada», «Alineación estable» y «No se puede estimar con seguridad».
5. Nunca mostrar «perpendicular perfecto» sin calibración y umbrales medidos. Permitir disparar manualmente aunque no haya confianza.

## No confundir conceptos

- Nivel Core Motion 0.1.3: orientación del **teléfono con respecto a gravedad**.
- Contorno 2D: solo silueta proyectada. Por sí solo **no prueba** el ángulo 3D de un objeto arbitrario.
- Normal del plano: dirección 3D perpendicular a una superficie plana.
- Objetivo fotográfico: idealmente **eje óptico de la lente**, no exactamente la normal de la carcasa física. Debe considerarse óptica, orientación, estabilización y distorsión.
- Perpendicularidad: ángulo entre eje óptico y normal del plano. Para documentos, cuadros y fotografías planas es mensurable con supuestos/calibración. Para objetos volumétricos no existe una única «cara frontal» universal.

## Tres clases de superficies

| Clase | Ejemplos | Método inicial | Grado de certeza |
| --- | --- | --- | --- |
| Plana rectangular | DNI de prueba, A4, foto, cuadro, lámina, pantalla | Vision detecta cuatro esquinas + selección por toque. Luego estimación de pose del plano con cámara calibrada y líneas de fuga/ortogonalidad; si conocemos tamaño/ratio, homografía y validación adicional | Estimación verificable, no infalible |
| Plana irregular | Dibujo recortado, cartel irregular | Segmentar/marcar contorno y estimar el plano solo con información adicional (ARKit, múltiples vistas, calibración o superficie auxiliar) | Sin pose si faltan datos |
| Volumétrica / curvada | Ratón, etiqueta cilíndrica, caja compleja | Máscaras por instancia, estimación de caras/planos cuando existan; elección guiada de «cara» | Puede no tener perpendicularidad única |

Apple Vision expone `VNDetectRectanglesRequest` y devuelve `VNRectangleObservation` con 4 esquinas (coordenadas normalizadas). Para objetos no rectangulares existe `VNGenerateForegroundInstanceMaskRequest`, pero una máscara no determina el plano 3D. ARKit puede detectar planos y, en dispositivos compatibles, profundidad; la funcionalidad específica de `sceneDepth` requiere LiDAR.

## Coordinadas y calibración

- Vision: puntos normalizados `[0,1]` con origen abajo a la izquierda; ordenar TL → TR → BR → BL.
- Vista previa: usar transformaciones documentadas por AVFoundation y el recorte real `resizeAspectFill`. Nunca suponer que la pantalla y el sensor comparten el mismo aspecto/orientación.
- Frames: pasar orientación explícita al detector; asociar timestamp y configuración de lente activa para impedir contornos desplazados.
- La lente debe tener intrínsecos/centro óptico y distorsión caracterizados. Medir en un patrón plano conocido y comparar orientación estimada con una referencia independiente.
- En vistas casi frontales las líneas de fuga se vuelven numéricamente inestables; no forzar una orientación de falsa precisión. Usar seguimiento temporal/IMU como apoyo y un estado de confianza explícito.
- El toque no es una garantía semántica; si hay rectángulos anidados, priorizar contorno más pequeño que incluya el punto con posibilidad de cambiar/editar.

## Plan de versiones graduales (sin comprometer 0.1.3)

### DEV 0.1.4a — motor de detección, solo algoritmo (en main)

- `SurfaceGeometry.swift`: geometría convexa y selección mediante toque normalizado.
- `RectangularSurfaceDetector.swift`: candidatos con `VNDetectRectanglesRequest`.
- `SurfaceGeometryTests.swift`: área, hit testing, selección de rectángulos anidados, degenerados y auto-intersecados.
- **Todavía no conectado a la cámara ni mostrado en pantalla. No hay estimación 3D.** Ejecutar CI de GitHub para build y tests antes del siguiente paso.

### DEV 0.1.4b — selección visible en cámara

- Capturar frames de preview de manera controlada y analizar a una frecuencia limitada, sin bloquear `AVCapturePhotoOutput`. Comenzar con muestreo reducido y medición de latencia/CPU.
- Dibujar el contorno del candidato; toque selecciona rectángulo (y posibilidad de reajustar esquinas); conservar coordinación entre imagen, detección y overlay.
- El contorno se marca «seleccionado», **nunca «perpendicular»** todavía.
- Pruebas: documento A4, foto impresa, varios rectángulos próximos, iluminación lateral, sombra y fondos con bordes engañosos.

### DEV 0.1.5 — estimación de orientación relativa al plano

- Calibrar cámara intrínseca y distorsión; explorar líneas de fuga y pose del plano mediante correspondencias geométricas y verificación independiente.
- Fusionar información de giroscopio para estabilidad y flechas de corrección cuando exista confianza. Core Motion de gravedad sigue como modo alternativo o soporte.
- Evaluar error angular real, deriva, latencia, distancia, diferentes lentes y orientaciones; **no prometer ±1° ni «perfecto» sin prueba**.

### DEV 0.1.6 — más allá de rectángulos

- Máscaras de objetos en primer plano / plano irregular; evaluar ARKit y profundidad únicamente cuando el dispositivo lo soporte y el coste de ejecución sea aceptable.
- Sin estimación fiable, dar guía de encuadre/nitidez/luz y captura manual sin inventar orientación.

## Criterios de seguridad y calidad

- Todo local por defecto. No enviar imágenes, frames, posiciones o metadatos a servicios externos.
- Detección debe poder desactivarse sin afectar a cámara ni fotos.
- Las mediciones de confianza y los falsos positivos se registran solo con patrones sin datos privados.
- Si la confianza cae, desaparece el verde; no retener «alineado» cuando el objetivo se pierde.
- Introducir corrección de perspectiva solo como copia derivada claramente señalizada; preservar JPEG original.
- Benchmark con tarjetas y superficies reales, distintos tamaños, inclinaciones y luces. Comparar resultados con/sin guía y registrar tiempo, fallos, nitidez, geometría y consumo.

## Referencias verificadas

- Apple Vision VNDetectRectanglesRequest: https://developer.apple.com/documentation/vision/vndetectrectanglesrequest
- Apple Vision VNRectangleObservation: https://developer.apple.com/documentation/vision/vnrectangleobservation
- Apple Vision VNGenerateForegroundInstanceMaskRequest: https://developer.apple.com/documentation/vision/vngenerateforegroundinstancemaskrequest
- Apple ARKit plane detection: https://developer.apple.com/documentation/arkit/tracking-and-visualizing-planes
- Apple ARKit sceneDepth (LiDAR): https://developer.apple.com/documentation/arkit/arconfiguration/framesemantics-swift.struct/scenedepth
