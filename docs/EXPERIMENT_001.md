# EXP-001 — ¿Ayudar antes de disparar mejora la captura?

**Estado:** diseñado, aún no ejecutado.
**Hardware inicial previsto:** iPhone 12 del proyecto; confirmar modelo y versión del SO en el momento de prueba.
**Fecha de definición:** 2026-10-23.

## Preguntas experimentales

H1. Un indicador de nivel bien calibrado reduce errores de inclinación al fotografiar una lámina plana horizontal frente a hacerlo sin ayuda.

H2. La guía de encuadre reduce cortes y la necesidad de repetir la fotografía.

H3. La guía adicional no empeora significativamente el tiempo, la temperatura, la estabilidad ni la comprensión de la interfaz.

Las hipótesis NO se dan por confirmadas por la mera existencia de sensores.

## Material sin datos personales

- Lámina A4 con cuadrícula, cuatro marcas de esquina, caracteres pequeños y líneas de alto contraste.
- Ilustración o fotografía impresa mate con colores variados.
- Fotografía impresa brillante o tarjeta plastificada para reflejos.
- Superficie horizontal y soporte inclinado ajustable.
- Regla/ángulo de referencia y fuente de luz cuya posición pueda repetirse.

**Nunca almacenar ni subir DNI, expedientes privados u otras imágenes sensibles en el repositorio público.**

## Diseño de prueba

- Dos condiciones: cámara estándar sin ayudas y Fielens experimental con ayudas. Mantener mismo móvil/lente/resolución/aproximación/iluminación; documentar excepciones.
- Repetir escenarios de forma balanceada y variar orden cuando participen usuarios para evitar que aprendizaje de una app beneficie siempre a la otra.
- Introducir ángulos de inicio repetibles, luz uniforme, luz lateral y soporte inclinado.
- Registrar primero referencias geométricas y condiciones de iluminación sin interpretación subjetiva.
- La selección de participantes, repeticiones y umbrales vendrá tras piloto; no inventar significación estadística con N pequeño.

## Variables

**Entrada:** dispositivo, lente, fecha, OS, iluminación, tipo de soporte, orientación conocida, distancia aproximada, resolución.

**Salida:** tiempo hasta captura, intentos, porcentaje de recorte, desviación de alineación del patrón, nitidez local de regiones de control, reflejos destacados, desviación visual/color si hay patrón, satisfacción y problemas percibidos.

**Rendimiento:** duración de sesión, frames descartados, lag perceptible, memoria y temperatura observada (no afirmar medir temperatura interna si el SO no la expone).

## Resultado y criterio de continuación

Publicar tabla con entradas, capturas anónimas permitidas y cálculo reproducible. Solo pasar a autocaptura si el nivel es correcto y las condiciones previas están estables. Si la guía no mejora resultados, rediseñar antes de añadir complejidad.

## Informe de cada sesión

- Commit, versión, dispositivo y SO:
- Escenario y luz:
- Protocolo seguido:
- Referencia sin ayuda:
- Resultado Fielens:
- Datos obtenidos:
- Posibles sesgos:
- Fallos:
- Decisión: repetir / corregir / avanzar.
