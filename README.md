# Fielens

**Cámara asistida universal · En desarrollo · Objetivo: Shipaton 2027**

> Captura fielmente lo que importa.

Fielens pretende ayudar a cualquier persona a obtener una reproducción digital **fiel, nítida y fácil de compartir** de un soporte físico: documentos, fotografías impresas, dibujos, obras gráficas, recibos, etiquetas, tarjetas y otras superficies.

Su diferencia principal: **asistir antes de disparar**, no limitarse a reparar después una mala imagen.

## Estado

- Inicio del proyecto: 23 de octubre de 2026.
- Nombre Fielens: elegido para el proyecto; registro de marca, tiendas y dominios pendientes de verificar.
- Fase: definición, investigación y especificación.
- Objetivo de primera publicación: agosto/septiembre de 2027, condicionado a las reglas oficiales del Shipaton 2027.
- Tecnología y arquitectura definitivas: por evaluar experimentalmente.
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

Actualmente no existe aún una aplicación funcional ni se ha elegido un stack definitivo.

## Primer estudio contrastado (2026-10-23)

- [Investigación comparativa inicial](docs/RESEARCH_2026-10-23.md)
- [Viabilidad técnica documentada](docs/TECHNICAL_FEASIBILITY_2026-10-23.md)
- [EXP-001: protocolo de validación](docs/EXPERIMENT_001.md)

La investigación no equivale a un prototipo implementado; las características de terceros corresponden a declaraciones y documentación pública, pendientes de pruebas directas.

## Fielens DEV 0.1.1 — Primer experimento de cámara

El primer prototipo de AVFoundation con permiso y vista previa está en `apps/ios/Fielens` y documentado en [DEV_0.1.1_CAMERA.md](docs/DEV_0.1.1_CAMERA.md). **Su compilación y funcionamiento en iPhone aún no están verificados**; no hay todavía captura ni nivel.
