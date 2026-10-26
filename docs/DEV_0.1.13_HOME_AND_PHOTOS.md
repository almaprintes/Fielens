# DEV 0.1.13 — Menú inicial y Guardar en Fotos

**Fecha:** 2026-10-26 12:11 (Atlantic/Canary).
**Motivación:** el creador confirma que el recorte de objeto funciona «casi perfecto» incluso con iluminación adversa. Quiere salir a probar con el iPhone desconectado, pero solicita primero que Fielens **no abra directamente la cámara** y que pueda **guardar en el carrete de iOS** la foto resultante.
**Estado:** Implementación en rama `main`; falta confirmar GitHub Actions del SHA final y el permiso/guardado real en el iPhone.

## Experiencia de inicio

- Pantalla principal oscura, tipografía elegante y motivos beige cálido, coherente con la línea visual de Fielens.
- Botón principal «Abrir cámara». **Al entrar en Fielens no se arranca `AVCaptureSession`, Core Motion ni se solicita permiso de cámara.** Los sensores se encienden únicamente al iniciar el modo de fotografía.
- Ajuste previo «Resolución de foto», con los cuatro perfiles actuales. Su elección se mantiene al abrir la cámara.
- «Volver al inicio» en cámara y revisión; al salir, se detienen cámara/seguimiento y sensores. Las fotos temporales del último disparo se descartan cuando se vuelve a inicio. No eliminar archivos previamente almacenados en Fotos.
- Volver del segundo plano solo reactiva cámara si se sigue en modo fotografía. La pantalla inicial no consume sensores ni muestra preview.

## Guardar en Fotos

- En la revisión se añade **«Guardar en Fotos»** separado de Compartir y Repetir.
- Guarda **exactamente el JPEG de la vista de revisión**: Ligera/Compartir/Detalle recortada si esa opción está activa y Vision pudo detectarla; Original sin modificar cuando el usuario lo elige. No hay segunda conversión, ni recompresión ni guardado automático.
- API: `Photos` / `PHPhotoLibrary.authorizationStatus(for: .addOnly)`, `PHPhotoLibrary.requestAuthorization(for: .addOnly)` y `PHAssetCreationRequest.addResource(with: .photo, fileURL:options:)` dentro de `performChanges`.
- Propiedad `PHAssetResourceCreationOptions.shouldMoveFile = false`: el archivo temporal sigue siendo utilizable durante el guardado y no se retira del directorio de Fielens por Photos.
- Privacidad: añade `NSPhotoLibraryAddUsageDescription` a las configuraciones del target iOS; **no solicita permiso de leer fototeca** ni accede a otras fotografías. Nunca solicita permiso de Fotos al abrir la aplicación, solo cuando el usuario intenta guardar.
- Durante el guardado se desactivan acciones que pudieran borrar/modificar el archivo, incluido Repetir, cambiar resolución, volver al inicio y volver a guardar. Se muestra «Guardando en Fotos…» y, después, éxito o error; no mostrar «guardado» sin confirmación de PhotoKit.
- La selección de destino es el carrete de Photos, distinto del sistema existente de «Compartir → Guardar en Archivos».

## Limitaciones conocidas

- El nuevo inicio es básico y deliberado, sin catálogo/galería propia ni persistencia de fotografías dentro de Fielens.
- Un permiso denegado debe explicarse y permitir corregirlo en Ajustes, pero no bloquea la exportación a Archivos.
- iOS puede gestionar metadatos EXIF/GPS del JPEG de cámara Original: la copia derivada no hereda EXIF, mientras Original conserva lo que la cámara proporcione.
- Fotos puede indexar/sincronizar los elementos según ajustes del usuario (Fotos en iCloud), de forma ajena a Fielens. No afirmar que guardar al carrete equivale a copia «solo local» perpetua.
- La autorización add-only no da derecho a enumerar ni recuperar después las fotografías de la biblioteca.
- Sin cambios en geometría, cámara AVFoundation ni procesamiento del JPEG de la DEV 0.1.12; esta versión prioriza flujo y guardado.

## QA obligatorio en iPhone

- [ ] Compilación con Xcode 26.6 en GitHub Actions para el SHA final.
- [ ] Tests Swift existentes verdes en simulador, sin asumir cobertura de permisos reales de Photos.
- [ ] Abrir Fielens desde cero: aparece la pantalla de bienvenida, **la vista de cámara no se abre sola** ni solicita cámara/Fotos.
- [ ] Cambiar resolución desde inicio; pulsar Abrir cámara: comprobar perfil elegido, nivel y detección automática.
- [ ] Volver a inicio desde cámara: se apaga cámara; reabrir: permisos ya concedidos y vista activa normalmente.
- [ ] Fotografiar una hoja ficticia, verificar recorte. En revisión pulsa **Guardar en Fotos**.
- [ ] Primer guardado: iOS solicita permiso **Añadir solo fotos** si no estaba autorizado. Conceder y esperar mensaje de éxito. Abrir app Fotos manualmente para confirmar nueva imagen.
- [ ] La fotografía de Fotos tiene las dimensiones visibles en la revisión y el mismo recorte/perspectiva.
- [ ] Sin repetir, seleccionar Original: Guardar en Fotos; comprobar que esa segunda imagen contiene el encuadre completo y resolución original.
- [ ] Probar Ligera y Detalle; verificar tamaños y que no aparezcan imágenes duplicadas inesperadamente (salvo pulsar guardar varias veces).
- [ ] Pulsar denegar autorización en un entorno de pruebas o desde Ajustes: Fielens informa sin caída. «Compartir» debe continuar funcionando.
- [ ] Volver al inicio desde revisión (sin guardar) y comprobar que el original temporal se descarta. Hacer nueva foto después.
- [ ] Suspender, reanudar, rotar y repetir; no quedar guardando indefinidamente ni activar cámara en home.
- [ ] Comprobar diseño táctil en pantalla pequeña, Dynamic Type y VoiceOver.
- [ ] Registrar resultados de QA y logs sin subir fotos reales de DNI al repositorio público.

## Criterios de cierre

Hito aceptado solo cuando se confirme en el iPhone **inicio sin cámara**, navegación inicio→cámara→revisión→inicio, permiso add-only, guardado real del JPEG seleccionado en Fotos y funcionamiento intacto de Compartir, Repetir, niveles y reconocimiento.

Enlaces Apple: https://developer.apple.com/documentation/photos/phphotolibrary y https://developer.apple.com/documentation/bundleresources/information-property-list/nsphotolibraryaddusagedescription


### Primera verificación CI — 2026-10-26

[GitHub Actions run 40321151785](https://github.com/almaprintes/Fielens/actions/runs/40321151785), commit `d024229a994b965834415401135ce4fae987337a`: **compilación iOS exitosa con Xcode 26.6**. Los cambios posteriores a este SHA fueron únicamente documentales. El job «Swift unit tests on iOS simulator» seguía ejecutándose en la última comprobación, por lo que no se puede afirmar aún que las pruebas terminaran en verde. La autorización add-only y la aparición real en el carrete **no se pueden verificar en CI** y exigen ensayo físico.
