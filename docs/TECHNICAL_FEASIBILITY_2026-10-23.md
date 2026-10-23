# Viabilidad técnica — Estudio documental 01

Fecha: 2026-10-23. **No hay implementación ni mediciones en dispositivo aún.**

## iPhone: tecnologías candidatas para el primer experimento

| Necesidad | API documentada | Limitación a investigar |
|---|---|---|
| Vista de cámara + foto de resolución completa | AVFoundation: AVCaptureSession, AVCapturePhotoOutput | Permisos, formatos, coste, diferencias entre preview y fotografía final |
| Fotogramas para análisis en vivo | AVCaptureVideoDataOutput | Latencia, colas, buffers, conversión y calor |
| Nivel físico y estabilidad | Core Motion: CMMotionManager / CMDeviceMotion | Gravedad solo da inclinación respecto al suelo; sesgos y temblor |
| Rectángulos y cuatro esquinas | Vision: VNDetectRectanglesRequest | Falsos positivos, superficies no rectangulares, coste computacional |
| Seguimiento de bordes en vídeo | Vision: seguimiento de rectángulos | Deriva y pérdida de seguimiento |
| Corrección de geometría | Core Image / transformación proyectiva a evaluar | Conservar detalle, relación de aspecto y original |
| Señales de enfoque/exposición | AVCaptureDevice + análisis visual | «No ajustando enfoque» NO equivale a «imagen nítida» |
| Interfaz accesible | SwiftUI/UIKit | Usabilidad aún por validar |

Referencias oficiales:
- https://developer.apple.com/documentation/avfoundation/avcapturephotooutput
- https://developer.apple.com/documentation/avfoundation/avcapturevideodataoutput
- https://developer.apple.com/documentation/coremotion/cmdevicemotion
- https://developer.apple.com/documentation/vision/vndetectrectanglesrequest
- https://developer.apple.com/documentation/vision/tracking-multiple-objects-or-rectangles-in-video
- https://developer.apple.com/documentation/avfoundation/avcapturedevice/isadjustingfocus

## Android: ruta futura

**CameraX** ofrece Preview, ImageCapture e ImageAnalysis en una API moderna. ML Kit Document Scanner aporta su propio flujo/UI para documentos, pero no resuelve automáticamente una interfaz personalizada Fielens ni garantiza sensores, tratamiento universal de obras o control fotográfico. Investigar módulos de geometría compartibles; no prometer paridad de cámara sin pruebas.

- https://developer.android.com/media/camera/camerax/architecture
- https://developers.google.com/ml-kit/vision/doc-scanner/android

## Corrección fundamental de geometría

- Nivel con gravedad: indica qué tan paralela está la **orientación del teléfono al plano horizontal**.
- Superficie sobre mesa horizontal: puede servir como ayuda para orientar el dispositivo.
- Soporte vertical o inclinado: gravedad por sí sola NO estima normal al soporte.
- Un cuadrilátero detectado puede servir para valorar la perspectiva de un rectángulo plano, pero la pose 3D exacta no queda garantizada sin supuestos geométricos, calibración y pruebas.
- Un documento sin bordes reconocibles, un cuadro enmarcado y un soporte curvo exigen tratamientos distintos.
- Las lentes, el centro óptico y la alineación entre sensor/objetivo y carcasa pueden introducir errores. Validar con patrón geométrico.

## Primer candidato tecnológico — NO decisión de arquitectura final

**Spike nativo iOS en Swift, usando AVFoundation + Core Motion; incorporar Vision después de tener métricas de cámara+sensores.** Justificación: acceso directo a APIs del sistema, menor incertidumbre inicial sobre permisos y captura que en un prototipo web. La decisión sobre app definitiva multiplataforma sigue abierta.

## Orden de validación

1. Permiso y vista previa estable.
2. Fotografía real a resolución que soporte dispositivo, guardado local.
3. Gravedad en ambos ejes, orientación visual verificable y botón manual.
4. Registro de estabilidad y latencia entre muestras.
5. Detección de rectángulos sobre stream, sin interferir con captura.
6. Análisis de perspectiva y comparación frente a medición de referencia.
7. Calidad visual: nitidez, reflejos, exposición y fidelidad de color.

### Criterios de bloqueo

- Si falla el acceso a cámara o las autorizaciones, detener el experimento y diagnosticar.
- Si el indicador no representa correctamente la orientación, no añadir autocaptura.
- No declarar perpendicularidad física sin comparar con una referencia.
- Si el análisis deteriora fluidez/temperatura, perfilar antes de añadir funciones.
