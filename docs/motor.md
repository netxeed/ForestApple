# Motor: Python (pygame) o Godot

Documento de apoyo para decidir la pregunta 16 de `docs/diseno.md`. Todo lo que
dice sobre Godot sale de conocimiento general de Godot 4.x: **no pude ejecutar
Godot** en mi entorno, así que nada de esto está probado aquí. Por eso hay un
checklist (sección 4) para comprobarlo en 30 minutos con el editor en la mano.

## 1. Qué necesita el juego

| Necesidad | Dónde pesa |
|---|---|
| Mapas con colisiones, NPCs, zonas que disparan eventos, cinemáticas | Acto 1 (RPG de exploración) |
| Diálogo con máquina de escribir, pausas, quién habla, banderas de historia | Todo el juego |
| Combate de sala (Isaac): jugador, enemigos, proyectiles, jefes con fases | Acto 2 |
| Pipeline de arte: sprites, animaciones, mapas hechos por la artista | Todo el juego |
| Android como plataforma real | Todo el juego |
| Equipo de 3, sin fecha | Mantenibilidad |

## 2. Comparación

| | Python + pygame-ce (hoy) | Godot 4 |
|---|---|---|
| Mapas y colisiones | A mano (`rooms/layout.py`, `room.py`). Para el Acto 1 habría que sumar un formato de mapa y un editor externo (p. ej. Tiled) | TileMap/TileSet y colisiones en el editor |
| NPCs, zonas, eventos | Hay que diseñar el sistema (banderas, triggers) | Nodos `Area2D`, señales y escenas reutilizables: se arma en el editor |
| Cinemáticas | Código a mano | `AnimationPlayer` y Tweens |
| Arte | La artista entrega PNG y alguien los conecta por código | Importa PNG, anima y arma mapas ella misma en el editor |
| Android | `buildozer.spec` hecho, **sin probar en un teléfono**; es la parte frágil del stack | Exportación oficial (requiere Android SDK/JDK y plantillas de exportación) |
| Controles táctiles | `core/touch_controls.py` (294 líneas, a mano) | `TouchScreenButton` y emulación de ratón/táctil |
| Pruebas automáticas | 105 tests + partida de humo en CI (lo mejor que tenemos hoy) | Posible (GUT o escenas de prueba en modo headless), pero hay que montarlo desde cero |
| Control del código | Total y transparente | Escenas `.tscn` en texto, pero los merges entre 3 personas son más delicados |
| Curva de entrada | Ya conocida por el equipo | GDScript es parecido a Python, pero hay que aprender el editor |
| Costo de cambiar | 0 | Reescribir código (ver sección 3) |

**Lectura:** para el Acto 2 (combate de sala) Python ya funciona. Para el
Acto 1 y para el trabajo de la artista, Godot ahorra mucho. El riesgo de Godot
es el costo de migración y una nueva herramienta en el flujo de 3 personas; el de
Python es seguir construyendo a mano lo que un editor da hecho.

## 3. Qué se migra y qué se descarta (si se pasa a Godot)

| Parte actual | Destino |
|---|---|
| `data/dialogues.json` | **Se conserva tal cual**; Godot lee JSON (`JSON.parse_string`) |
| `data/enemies.json`, `rooms.json`, `floor1.json` | Se conservan como datos de diseño; el cargador hay que reescribirlo |
| `dialogue/text.py`, `runner.py`, `lines.py` | Reescribir en GDScript (lógica de unas 340 líneas, bien separada y con tests que sirven de especificación) |
| `states/*` (pila de estados) | Se reemplaza por escenas y `change_scene`; Godot lo da hecho |
| `entities/*`, `rooms/*` | Reescribir (≈1.500 líneas), sobre todo `watermelon.py` y `room.py` |
| `core/touch_controls.py`, `viewport.py`, `preferences.py` | Se reemplazan por piezas del motor |
| Tests y CI | Los de lógica pura sirven como especificación; la CI habría que rehacerla |

Una migración completa del prototipo actual es del orden de **días de trabajo**,
no semanas, porque el juego es pequeño. Aun así el Acto 2 no hace falta migrarlo
ya: el prototipo Python queda como referencia y se migra cuando haya decisión.

## 4. Checklist de 30 minutos (se hace con Godot 4.x instalado)

Con el proyecto de `godot/` (ver la rebanada, si ya está en el repositorio):

1. [ ] Abre el proyecto: ¿carga sin errores en la consola?
2. [ ] Ejecuta la sala: ¿se mueve la manzana con flechas/WASD y colisiona con las paredes?
3. [ ] Acércate a un NPC y pulsa Z/Enter: ¿sale el diálogo con máquina de escribir y pausas?
4. [ ] ¿Se lee `data/dialogues.json` sin modificarlo? ¿Los nombres de quien habla salen bien?
5. [ ] Arrastra un PNG a la carpeta de sprites: ¿cuánto cuesta reemplazar el cuadrado de la manzana?
6. [ ] Exporta a escritorio (o a Android si tienes SDK): ¿cuánto tardó y qué hubo que instalar?
7. [ ] Pide a la artista que abra el editor 10 minutos: ¿puede mover un tile y animar un sprite sin ayuda?

## 5. Criterios para decidir

Godot gana si se cumple la mayoría:

- La artista puede trabajar sola en el editor (punto 7).
- El diálogo y el movimiento se sienten igual o mejor que en pygame con poco código.
- La exportación a Android funciona sin pelear (punto 6).
- A los tres les resulta cómodo el flujo con Git y las escenas `.tscn`.

Python gana (o se queda para el Acto 2) si:

- Instalar y exportar es un problema recurrente para alguien del equipo.
- Los conflictos de merge en escenas son frecuentes.
- La prioridad es terminar el combate del Acto 2 antes que pulir el Acto 1.

**Opción mixta, no excluyente:** Godot para el Acto 1 y Acto 3 (exploración y
diálogo), Python para el Acto 2. No la recomiendo: dos motores en un mismo juego
obligan a mantener dos bases de código y guardado/estado compartidos.

## 6. Qué no sé

- Cómo se comporta el rendimiento y el táctil de Godot en el teléfono del equipo.
- Si hay una versión concreta de Godot que convenga fijar (conviene anotarla al decidir).
- El tamaño real de la migración del combate (patrones de proyectiles, fases del jefe).
