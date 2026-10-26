# Fielens DEV 0.1.4 — Resoluciones para compartir

**Fecha de implementación:** 2026-10-26.
**Estado:** Código en rama main. La ejecución en iPhone físico NO se ha validado; compilación y tests GitHub Actions deben confirmarse por SHA.
**Problema:** no tiene sentido adjuntar siempre una captura de 8064 × 6048 px (48,77 MP) y alrededor de 11,5 MB para enviar una copia legible de un DNI por mensajería.

## Modelo deliberado: resolución de exportación frente a resolución de captura

Fielens sigue capturando JPEG a máxima resolución compatible con la sesión, sin alterar el original temporal. El usuario elige **resolución del archivo compartido**, antes de fotografiar o en pantalla de revisión. La copia comprimida se prepara solo si el usuario pulsa Compartir; no se envía automáticamente. Esta decisión prioriza poder cambiar de salida sin repetir la captura. Más adelante se evaluará capturar nativamente a menor resolución para reducir tiempo, memoria y consumo.

| Opción | Lado mayor máximo | Aproximación en 4:3 | JPEG quality | Uso |
| --- | ---: | ---: | ---: | --- |
| Ligera | 1600 px | 1600 × 1200 (1,9 MP) | 0,82 | imágenes pequeñas |
| Compartir (predeterminada) | 2400 px | 2400 × 1800 (4,3 MP) | 0,88 | WhatsApp y documentos |
| Detalle | 4000 px | 4000 × 3000 (12 MP) | 0,92 | letra fina, impresión |
| Original | sin límite de conversión | hasta 8064 × 6048 observado en iPhone (48,77 MP) | sin recodificar | conservar todos los píxeles y EXIF |

El lado mayor real **nunca crece** por encima de la imagen fuente; los valores son máximos, no resoluciones garantizadas. La compresión JPEG no tiene tamaño fijo en MB, ni garantiza legibilidad cuando hay falta de foco, reflejos o recorte. WhatsApp puede transformar los archivos que se envían como imágenes; enviar como documento puede conservar el archivo adjunto, pendiente de prueba con distintas versiones.

## Cambios

- `PhotoExportService.swift`: enum `ExportResolution`, política de máximos, miniatura orientada y JPEG derivado con ImageIO, calidad por perfil. La copia tiene nombre aleatorio en carpeta privada temporal.
- `ContentView.swift`: selección de resolución en cámara y revisión, uso predeterminado «Compartir», exportación en tarea separada del hilo principal, hoja nativa de compartir, progreso, error y limpieza de archivo generado al cerrar la hoja.
- `project.pbxproj`: `MARKETING_VERSION 0.1.4`, build 5; la DEV 0.1.4a de detección Vision permanece como módulo no conectado a UI.
- `PhotoExportTests.swift`: test de original byte a byte, cotas de dimensiones, no ampliación de originales pequeños, limpieza de copia y ausencia de GPS en derivado. Los tests requieren que CI termine correctamente.

## Privacidad y limitaciones

- Los originales y las copias residen en carpeta temporal privada de Fielens hasta su eliminación; las copias se limpian tras descartar la hoja nativa. En caso de cierre abrupto, el directorio temporal puede quedar hasta próximo inicio/limpieza del sistema.
- El original no sufre cambios y **conserva metadatos**, posiblemente ubicación y datos de dispositivo; si se comparte «Original» deben conocerse esas implicaciones.
- Al recomprimir desde una imagen decodificada, las copias reducidas **no heredan los metadatos originales**. Las propiedades técnicas del nuevo JPEG, si las añade la API, no equivalen a copia exacta.
- No se debe subir DNI, pasaporte u otros documentos reales como fixtures de tests ni a GitHub, aunque el repositorio sea público. Utilizar un documento ficticio con texto fino y números de prueba.
- Esta entrega no introduce desenfoque, redacción de datos, marcas de agua ni reglas de cumplimiento documental específicas. Una copia reducida no equivale a un tratamiento de seguridad.
- Compartir por WhatsApp no está automatizado; la hoja de iOS entrega el archivo y el usuario elige el destino. El proveedor podría recomprimir al mandar como foto.
- En imágenes de gran resolución vigilar memoria, latencia, cierre de hoja y orientación EXIF (se normaliza orientación de la copia).

## Pruebas de aceptación en iPhone (pendientes)

- [ ] Compilación GitHub Actions iOS en verde del SHA exacto de esta versión.
- [ ] Tests de unidad `PhotoExportTests` en simulador, sin fallos.
- [ ] En iPhone, captura con ajustes predeterminados y revisión: original sigue mostrando 8064 × 6048 px en dispositivo de ensayo, si el sensor entrega esas dimensiones.
- [ ] Cambiar a Ligera y Guardar en Archivos: lado mayor de JPEG exportado no superior a 1600 px.
- [ ] Cambiar a Compartir y repetir exportación de *la misma captura*: lado mayor no superior a 2400 px.
- [ ] Cambiar a Detalle y exportar la misma captura: lado mayor no superior a 4000 px.
- [ ] Elegir Original y Guardar en Archivos: verificar igualdad de dimensiones/bytes respecto al JPEG temporal inicial, cuando sea posible.
- [ ] Abrir copias guardadas en Archivos: revisar orientación, lectura de texto fino, encuadre y calidad, sin estiramientos.
- [ ] Comprobar que copiar y compartir no altera el archivo original; comprobar limpieza de copias temporales.
- [ ] Ensayar varios ciclos de compartir y Repetir; ausencia de congelaciones; cámara y Core Motion siguen funcionando.
- [ ] Revisar metadatos de una copia ficticia con GPS simulado: copia derivada sin GPS, original intacto.
- [ ] Medir en condiciones constantes tiempo de preparación, bytes reales y legibilidad, evitando promesas de tamaños fijos.
- [ ] Registrar dispositivo, versión iOS, commit exacto, tres tamaños y posibles defectos.

## Siguiente pregunta de producto

¿Conviene capturar nativamente a 12 MP cuando el usuario ha escogido «Compartir»? Antes de implementarlo, comparar coste de captura 48 MP + reducción contra 12 MP directo, manteniendo legibilidad de caracteres mínimos y experiencia de enfoque. Evitar cambios prematuros en AVFoundation sin datos.

**Estado actual de aceptación:** desarrollo implementado, sin prueba física.
