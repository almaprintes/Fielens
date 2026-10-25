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
| H-008 · Captura DEV 0.1.2 | 2026-10-25 23:17 | **Captura y lectura de resolución verificadas por el creador; QA parcial** | Primera fotografía reportada desde iPhone: 8064 × 6048 píxeles (48,77 MP), JPEG ~11,5 MB. Aún sin confirmar repetir, exportar archivo intacto, ciclo de vida ni pruebas automáticas |
| H-009 · Nivel digital (posterior) | Pendiente | Sin implementar | Core Motion; calibración, estabilidad y comparación EXP-001 |
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
