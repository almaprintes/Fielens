# Fielens — Registro de hitos

**Norma:** los hitos tienen fecha, evidencia, estado y criterios. No confundir "archivo subido" con "compila" ni "compila" con "prueba real aprobada". Las fechas y los resultados de la prueba manual proceden de los informes del creador. El repositorio permanece público: no subir imágenes privadas, claves ni datos personales.

| Hito | Fecha | Estado | Evidencia / comprobación |
| --- | --- | --- | --- |
| H-001 · Definición de producto universal | 2026-10-23 | Decisión tomada | Visión aceptada: fotografía asistida de documentos, fotografías impresas, arte y cualquier soporte físico para compartir |
| H-002 · Nombre Fielens | 2026-10-23 | Nombre elegido; marca pendiente | Decisión del creador y `docs/DECISIONS.md` |
| H-003 · Repositorio y protocolo de rigor | 2026-10-23 | Completado | `README.md`, `AGENTS.md`, `PROJECT_HANDOFF.md`, `docs/` en GitHub |
| H-004 · Investigación técnica inicial | 2026-10-23 | Investigación documental completada; benchmark pendiente | `docs/RESEARCH_2026-10-23.md`, `docs/TECHNICAL_FEASIBILITY_2026-10-23.md`, `docs/EXPERIMENT_001.md` |
| H-005 · Entorno iOS funcional | 2026-10-25 | Verificado por el creador en Mac/iPhone | Xcode 26.6 + soporte iOS 26.5 + firma Personal Team; `Hello, world!` ejecutado físicamente |
| H-006 · Versión inicial respaldada en GitHub | 2026-10-25 | Confirmado en repositorio | Proyecto `apps/ios/Fielens` en `main`; commit `070d908` inicial de Xcode |
| H-007 · Cámara DEV 0.1.1 | 2026-10-25 ~23:00 | **Verificado: cámara en directo** | El creador confirmó «funciona» tras `⌘B`/`⌘R` en iPhone; AVFoundation + gestión básica de permiso. Pruebas de ciclo de vida/denegación y métricas aún pendientes |
| H-008 · Captura DEV 0.1.2 | 2026-10-25 23:17–23:28 | **Captura, Repetir y Guardar en Archivos confirmados; QA parcial** | 8064 × 6048 (48,77 MP), ~11,5 MB en app; guardado en Archivos ~11,7 MB. El creador confirma que Repetir funciona. Sin hash de exportación, pruebas automáticas ni ciclo de vida |
| H-009 · Nivel digital DEV 0.1.3 | 2026-10-25 23:41 | **Lectura física y ejecución en iPhone confirmadas; QA parcial** | Capturas del creador: A X −0,2°, Y −0,2°; B X −0,1°, Y −0,4°, ambas verdes. Prueba al borde de mesa para sortear resalte de cámara; precisión sin calibrar. [Protocolo](DEV_0.1.3_LEVEL.md) |
| H-011 · Compilación remota GitHub Actions | 2026-10-25 | **Compilación confirmada en verde** | [Run #1](https://github.com/almaprintes/Fielens/actions/runs/40246527085) con Xcode 26.6 y iOS SDK 26.5; segundo job de tests en simulador añadido, primera ejecución pendiente |
| H-012 · Detección de superficies EXP-002 / DEV 0.1.4a | 2026-10-25/26 | **Módulo en main, compilación iOS verificada; tests en simulador pendientes** | [Build cloud](https://github.com/almaprintes/Fielens/actions/runs/40247295733), detección Vision y selección por toque en modelo. No hay interfaz ni pose 3D. [Diseño](SURFACE_TARGETING_DESIGN.md) |
| H-013 · Resoluciones de exportación DEV 0.1.4 | 2026-10-26 | **Código y pruebas añadidos, QA pendiente** | Ligera 1600px, Compartir 2400px, Detalle 4000px, Original sin cambios. [Protocolo](DEV_0.1.4_EXPORT.md); no probado todavía en iPhone |
| H-014 · DEV 0.1.5: resultado acorde a resolución | 2026-10-26 09:49 | **Resultado Ligera verificado visualmente en iPhone; QA adicional pendiente** | Captura de pantalla DEV 0.1.6 muestra Ligera 1200 × 1600 px = 1,92 MP y 345 KB. El original y las otras tres opciones no se probaron en esta sesión. [QA](DEV_0.1.5_REVIEW_RESOLUTION.md) |
| H-015 · DEV 0.1.6: contornos en cámara y selección por toque | 2026-10-26 09:49–09:55 | **Detección visible confirmada en iPhone; precisión táctil insuficiente** | Captura real: contorno menta sobre hoja y varios candidatos; usuario confirma «La detección al toque no es nada precisa». Sin pose 3D. [QA](DEV_0.1.6_SURFACE_PREVIEW.md) |
| H-016 · DEV 0.1.7: nivel compacto | 2026-10-26 | **Implementado en main; sin prueba física** | Nivel se reduce y desplaza hacia arriba para despejar el objetivo. [QA](DEV_0.1.7_COMPACT_LEVEL.md) |
| H-017 · DEV 0.1.8: precisión del toque | 2026-10-26 | **Compilación remota verde; tests e iPhone pendientes** | Selección por el mismo polígono proyectado que se dibuja, prioridad a hoja frente a pequeños recuadros, botón Otro. [QA](DEV_0.1.8_TOUCH_PRECISION.md) |
| H-018 · DEV 0.1.9: orientar correctamente el contorno | 2026-10-26 10:16 | **Código en main, QA física pendiente** | Captura de iPhone DEV 0.1.8 confirma que el polígono no sigue la hoja; corregida inversión de rotación `.right` entre Vision y sensor, forzado videoRotationAngle=0 y tests de esquinas. [QA](DEV_0.1.9_ORIENTATION_MAPPING.md) |
| H-019 · DEV 0.1.10: ajustar manualmente cuatro esquinas | 2026-10-26 10:40 | **Compilación iOS confirmada; tests y QA física pendientes** | En 0.1.9 solo una esquina de la hoja se detecta muy baja, formando una diagonal. Modo de 4 puntos arrastrables, Restaurar/Listo y detección estricta con respaldo. [QA](DEV_0.1.10_MANUAL_CORNERS.md) |
| H-010 · Candidatura Shipaton 2027 | Ago–sep 2027 objetivo | Condicional | Comprobar reglas de la convocatoria 2027 antes de primera publicación pública |

## Lecciones y fallos útiles

- El Xcode inicial no compilaba con equipo `None`: se configuró firma Personal Team.
- La plataforma iOS 26.5 faltaba a pesar de disponer de SDK. Se recuperaron ~24 GiB eliminando **solo** modelos OpenVINO descargados de Audacity que no se necesitaban; se preservaron los proyectos de Top Down RACE.
- Xcode creó un segundo repositorio Git anidado. Se respaldó su carpeta `.git` fuera del proyecto y se incorporaron los 10 archivos iOS al repositorio principal.
- `git push` por contraseña falló; se instaló y autorizó `gh`, y la subida se verificó.
- El primer intento de DEV 0.1.1 generó seis errores; se corrigió `import Combine` y la firma del cierre `onChange` antes de la prueba física positiva.

## Política de cierre

Un hito con software solo pasa a **validado** si incluye: commit, compilación reproducible, ejecución en dispositivo indicado, prueba funcional observada y defectos residuales anotados. Si faltan pruebas de regresión, describir la validación con su alcance real, nunca como auditoría completa.

### Evidencia adicional de H-008, 23:22

Recibida imagen de ensayo y revisada una copia de chat (JPEG 1536 × 2048, 503.960 bytes); no coincide en dimensiones ni peso con la captura indicada en Fielens (8064 × 6048, 11,5 MB). No supone fallo demostrado de la cámara: aún no se ha comparado el archivo original compartido mediante «Guardar en Archivos». Mantener H-008 **parcialmente verificado** hasta confirmar «Repetir» e integridad de la exportación.

### Aclaración adicional H-008 — 23:25

El creador confirma que **utilizó Guardar en Archivos desde Fielens**, donde la imagen conservada tiene **11,7 MB**. La copia recibida en ChatGPT es una versión de 1536 × 2048 píxeles mucho menor; es plausible una transformación durante el envío al chat, **no demostrada por una comparación binaria**. Se confirma la ruta funcional de exportación a Archivos, sin afirmar todavía identidad de bytes ni ausencia de cambios en intermediarios. Verificación final: dimensiones en Archivos, preferiblemente comparación del archivo original sin pasarlo por el chat.


### Evidencia parcial H-015 — CI

Compilación con Xcode 26.6 **verde** para commit `dafed1ff` en [GitHub Actions](https://github.com/almaprintes/Fielens/actions/runs/40297267434). Tests de simulador y build del último commit `0705e9c3` aún sin resultado verificado. No hay ninguna prueba física de detección por cámara; H-015 permanece abierto.
