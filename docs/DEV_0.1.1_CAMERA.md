# Fielens DEV 0.1.1 — Cámara en directo

**Fecha:** 2026-10-25
**Estado:** Código en main; pendiente de compilación y ejecución en el iPhone físico del usuario. NO declarar validada.
**Alcance:** Primera iteración de EXP-001, únicamente vista previa de cámara y permisos.

## Implementación

- `CameraSession.swift`: sesión AVFoundation, configuración y arranque/parada en cola serie, fuera del hilo principal.
- `CameraPreview.swift`: capa nativa `AVCaptureVideoPreviewLayer` dentro de SwiftUI. No guarda fotogramas.
- `CameraViewModel.swift`: estados y autorización de cámara; gestiona permiso denegado, cámara ausente, reintento y cambios de ciclo de vida.
- `ContentView.swift`: reemplaza Hello World con interfaz mínima de captura en vivo.
- `project.pbxproj`: `NSCameraUsageDescription` en las configuraciones de app, `MARKETING_VERSION = 0.1.1`, build 2.
- No se requiere permiso de micrófono ni de Fotos; esta versión no fotografía ni guarda imágenes.

## Comprobación manual obligatoria

1. Ejecutar `git pull --ff-only` dentro de `~/Developer/Fielens` y volver a abrir Xcode si es preciso.
2. Seleccionar el iPhone físico configurado y compilar con `⌘B`. Anotar errores exactos si aparecen.
3. Ejecutar con `⌘R` y conceder permiso de cámara: debe verse la imagen trasera en movimiento.
4. Girar/alejar/acercar y comprobar que la imagen responde; anotar si aparece mal orientada o deformada.
5. Ir a otra app y volver: comprobar que la cámara se reanuda.
6. Denegar permiso en Ajustes del iPhone: la app debe dar una explicación con opción «Abrir Ajustes».
7. Confirmar que no solicita acceso a micrófono/Fotos ni genera fotos o archivos.
8. Anotar modelo de dispositivo, versión iOS, fecha, commit y observaciones.

## No implementado todavía

- Captura y persistencia local de fotografías
- Nivel Core Motion y calibración
- Corrección de perspectiva, sombras, enfoque y contraste
- Detección de bordes y autocaptura
- Pruebas cuantitativas de EXP-001

## Riesgos abiertos

- Swift 6.2 / Xcode 26.6 pueden emitir nuevas advertencias de aislamiento; primero compilar y documentar.
- Verificar orientación, uso de CPU, memoria y la continuidad de preview al entrar/salir.
- El ajuste `.resizeAspectFill` puede recortar la previsualización; para captura de documentos se necesitará una política de encuadre verificada frente a la imagen final.
- La UI es diagnóstica, no definitiva.
- No publicar esta aplicación en ninguna tienda antes de validar reglas Shipaton 2027.

## Referencias

- Apple — AVFoundation / autorización: https://developer.apple.com/documentation/avfoundation/requesting-authorization-to-capture-and-save-media
- Apple — AVCam: https://developer.apple.com/documentation/avfoundation/avcam-building-a-camera-app
