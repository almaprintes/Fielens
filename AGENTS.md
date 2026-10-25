# AGENTS.md — Protocolo de desarrollo Fielens

1. El proyecto busca calidad excepcional para Shipaton 2027; evitar prisas y funciones sin criterio de aceptación verificable.
2. Una tarea acotada por iteración. Registrar hipótesis, cambios, pruebas y riesgos.
3. Mantener actualizados README.md, PROJECT_HANDOFF.md y los documentos en docs/.
4. Registrar decisiones relevantes con ID, fecha, motivo, alternativas y estado en docs/DECISIONS.md.
5. No elegir stack ni introducir dependencias antes de comprobar sus requisitos de cámara, sensores, visión y privacidad.
6. Nunca incluir credenciales, documentos personales, fotos sensibles o localizaciones de personas en código, registros, informes o repositorio.
7. Procesamiento local por defecto; cualquier conexión o sincronización futura requiere diseño explícito y consentimiento.
8. No inventar información de imágenes con IA ni sustituir silenciosamente contenidos originales. Preservar el original.
9. Medir calidad geométrica, nitidez, color, reflejos, latencia, memoria y consumo con pruebas repetibles.
10. El nivel de gravedad no equivale por sí solo a perpendicularidad respecto al soporte.
11. Usar main como rama de referencia, cambios trazables y verificaciones antes de integrar.
12. No publicar públicamente la app ni iniciar distribución abierta sin verificar las reglas oficiales Shipaton 2027.
13. «Fielens» es el nombre elegido; la protección legal de marca y disponibilidad comercial todavía deben investigarse.
14. No declarar un resultado como verificado sin prueba y condiciones de dispositivo identificadas.

## Registro obligatorio por iteración (desde DEV 0.1.2)

- Actualizar `docs/MILESTONES.md`: ID, fecha, versión, estado y evidencia.
- Actualizar `docs/DEVELOPMENT_LOG.md`: objetivo, commits, cambios, pruebas, errores, correcciones y siguiente paso.
- Actualizar `PROJECT_HANDOFF.md` con la situación **real** del código, dispositivo y pruebas pendientes.
- Para cada versión funcional, registrar un protocolo de QA en `docs/DEV_<version>_*.md` y distinguir **código subido**, **Build Succeeded**, **arranque** y **prueba funcional**.
- Nunca declarar probada una función que solo se haya revisado estáticamente. En iOS, solicitar datos de ejecución real en el iPhone del creador.
- Mantener el proyecto en rama main y evitar cambios grandes sin pruebas intermedias. No crear AAB, APK ni lanzamiento público por iniciativa propia.
