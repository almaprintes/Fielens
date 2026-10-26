# Fielens

**Cámara asistida universal · En desarrollo · Objetivo: Shipaton 2027**

> Captura fielmente lo que importa.

Fielens pretende ayudar a cualquier persona a obtener una reproducción digital **fiel, nítida y fácil de compartir** de un soporte físico: documentos, fotografías impresas, dibujos, obras gráficas, recibos, etiquetas, tarjetas y otras superficies.

Su diferencia principal: **asistir antes de disparar**, no limitarse a reparar después una mala imagen.

## Estado

- Inicio del proyecto: 23 de octubre de 2026.
- Nombre Fielens: elegido para el proyecto; registro de marca, tiendas y dominios pendientes de verificar.
- Fase: prototipo experimental iOS + investigación y pruebas.
- Objetivo de primera publicación: agosto/septiembre de 2027, condicionado a las reglas oficiales del Shipaton 2027.
- Prototipo actual: iOS nativo con SwiftUI/AVFoundation; arquitectura definitiva multiplataforma pendiente de decidir.
- El repositorio puede ser público; **el lanzamiento público de la app es una decisión distinta**.

## Principios

1. **Fidelidad:** no inventar texto, color ni detalle ausente.
2. **Privacidad:** procesamiento local y ninguna subida de capturas por defecto.
3. **Sencillez:** guía útil sin conocimientos previos de fotografía.
4. **Rigor:** mediciones reproducibles y pruebas en dispositivos reales.
5. **Captura primero:** detectar inclinación, recorte, desenfoque, reflejos y luz antes de disparar.
6. **Transparencia:** conservar el original y distinguir siempre las transformaciones.

## Primer hito técnico — v0.1 experimental

- Cámara en vivo en iPhone.
- Nivel digital de dos ejes basado en sensores.
- Captura manual y revisión.
- Exportación o guardado local.
- Protocolo de pruebas reproducible en hardware real.

**Precaución:** el nivel basado en gravedad no demuestra la perpendicularidad respecto a una superficie inclinada. La orientación relativa al soporte requiere análisis visual y validación.

## Documentación

- [Visión del producto](docs/VISION.md)
- [Hoja de ruta](docs/ROADMAP.md)
- [Barra de calidad](docs/QUALITY_BAR.md)
- [Decisiones](docs/DECISIONS.md)
- [Investigación](docs/RESEARCH.md)
- [Shipaton 2027](docs/SHIPATON_2027.md)
- [Reglas de trabajo](AGENTS.md)
- [Estado y traspaso](PROJECT_HANDOFF.md)

## Publicación

No lanzar la aplicación públicamente hasta verificar las bases oficiales del Shipaton 2027 y superar nuestras puertas de calidad. No subir al repositorio imágenes con datos personales, credenciales ni material confidencial.

La **DEV 0.1.1** ya mostró la cámara en vivo en un iPhone real, confirmado por el creador. La **DEV 0.1.2** está implementada en GitHub pero todavía NO está compilada ni probada en el dispositivo. El nivel Core Motion sigue pendiente.

## Primer estudio contrastado (2026-10-23)

- [Investigación comparativa inicial](docs/RESEARCH_2026-10-23.md)
- [Viabilidad técnica documentada](docs/TECHNICAL_FEASIBILITY_2026-10-23.md)
- [EXP-001: protocolo de validación](docs/EXPERIMENT_001.md)

La investigación no equivale a un prototipo implementado; las características de terceros corresponden a declaraciones y documentación pública, pendientes de pruebas directas.

## Fielens DEV 0.1.1 — Primer experimento de cámara

El primer prototipo de AVFoundation con permiso y vista previa está en `apps/ios/Fielens` y documentado en [DEV_0.1.1_CAMERA.md](docs/DEV_0.1.1_CAMERA.md). su compilación y vista previa en un iPhone real fueron confirmadas el 25/10/2026. El nivel aún no está implementado.

## Estado de versiones y evidencias

- [Registro de hitos](docs/MILESTONES.md)
- [Diario cronológico](docs/DEVELOPMENT_LOG.md)
- [DEV 0.1.2: capturar, revisar y compartir](docs/DEV_0.1.2_CAPTURE.md) — código en main; pendiente de Build y prueba en dispositivo.
- [DEV 0.1.1: primera cámara](docs/DEV_0.1.1_CAMERA.md) — vista previa confirmada por el creador.
- [Prueba experimental de captura asistida](docs/EXPERIMENT_001.md) — sin resultados medidos todavía.

**No introducir datos sensibles ni fotos de usuarios en GitHub.**

## DEV 0.1.3 — Nivel digital (pendiente de pruebas)

El primer nivel digital de dos ejes está implementado en `apps/ios/Fielens` con Core Motion y documentado en [DEV_0.1.3_LEVEL.md](docs/DEV_0.1.3_LEVEL.md). **El código está en main, pero todavía no está compilado ni probado en el iPhone.** El horizonte de gravedad NO es la perpendicular al soporte.

La DEV 0.1.2 ya tiene confirmadas por el creador captura, botón Repetir y exportación a Archivos. La identidad binaria del JPEG exportado, las pruebas automatizadas y las pruebas prolongadas siguen pendientes.

## Calidad y compilación cloud

[Fielens iOS Build](.github/workflows/ios-build.yml) permite compilar en GitHub Actions con Xcode 26.6 sin el Mac local. [Primer build verde](https://github.com/almaprintes/Fielens/actions/runs/40246527085). Se añadió un job de tests Swift en simulador iOS 26.5, sujeto a validación del primer resultado. Ver [manual CI](docs/IOS_CI.md).

## EXP-002 — Selección por toque y guía relativa al soporte

[Diseño de detección de superficies y perpendicularidad](docs/SURFACE_TARGETING_DESIGN.md). La DEV 0.1.4a aporta un primer módulo de detección de cuadriláteros con Vision y selección por toque, actualmente **sin UI conectada ni orientación relativa al objeto**. La detección es un candidato para soportes planos rectangulares, no un detector universal de plano/normal.

## DEV 0.1.4 — Resolución al compartir

Se puede elegir **Ligera (1600 px), Compartir (2400 px, predeterminada), Detalle (4000 px) u Original**. Fielens aún fotografía a resolución completa, pero crea solo al compartir una copia más ligera que no copia EXIF original; el JPEG original se mantiene intacto temporalmente. **Pendiente prueba real y regresiones en iPhone.** [Plan de validación](docs/DEV_0.1.4_EXPORT.md).
