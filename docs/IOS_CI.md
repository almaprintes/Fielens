# Compilación iOS sin Mac local — GitHub Actions

**Fecha de incorporación:** 2026-10-25
**Primera compilación verificada:** [Build verde en Xcode 26.6, commit adb1b0be](https://github.com/almaprintes/Fielens/actions/runs/40246527085)
**Automatización:** [Fielens iOS Build](../.github/workflows/ios-build.yml)
**Runner:** `macos-26` (Apple Silicon), Xcode 26.6, sin firma para distribución.

## Para qué sirve

La compilación se ejecuta en un Mac hospedado por GitHub al subir cambios a `main` que afecten `apps/ios/**` o el workflow. Se puede usar `workflow_dispatch` para iniciar el chequeo manualmente desde Actions. Detecta errores de compilación de Swift, recursos y configuración del proyecto sin encender el Mac físico del creador.

Comando de compilación: `xcodebuild -project apps/ios/Fielens/Fielens.xcodeproj -scheme Fielens -configuration Debug -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`. La carpeta DerivedData va al directorio temporal del runner, no al repositorio.

Verificar versión de Xcode, resultado del job y registro de errores en: https://github.com/almaprintes/Fielens/actions

Si falla, GitHub Actions proporciona los logs; el workflow intenta subir un artefacto de registros (retención limitada a 7 días). No se almacenan imágenes de usuario.

## Qué NO garantiza

- No instala ni ejecuta la app en un iPhone.
- No mide precisión ni latencia de acelerómetro/giroscopio, enfoque, captura fotográfica o temperatura.
- No comprueba permisos en ejecución, cámara tapada o escenas reales.
- Incorpora además un **segundo job de tests Swift en simulador iOS 26.5**, sin ejecutar UI Tests ni usar cámara real. La primera ejecución de ese job está pendiente de confirmación. No sustituye las pruebas de sensores sobre iPhone real.
- No crea IPA ni firma un binario listo para distribución.
- No reemplaza la compilación firmada y QA manual en un dispositivo físico.

## Reglas y costes

El repositorio Fielens era público en el momento de configurar este workflow. Los ejecutores estándar de GitHub Actions son gratuitos para repositorios públicos, según la documentación oficial; revisar tarifas y límites si la visibilidad cambia.

Referencias:
- https://docs.github.com/en/actions/reference/runners/github-hosted-runners
- https://github.blog/changelog/2026-02-26-macos-26-is-now-generally-available-for-github-hosted-runners/
- https://github.com/actions/runner-images/blob/main/images/macos/macos-26-Readme.md

## Puerta de calidad para futuros cambios

1. La compilación en Actions debe finalizar correctamente.
2. Ejecutar el job de tests Swift en el simulador iOS 26.5. Distinguir entre test **configurado** y test **pasado**; documentar siempre el resultado.
3. Para cambios de cámara/sensores: exigir adicionalmente ejecución y test en iPhone.
4. Registrar el SHA exacto del commit que superó la compilación en el diario de desarrollo.
5. No etiquetar «validado» un build con solo compilación en la nube.
