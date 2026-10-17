# Rebanada de prueba en Godot

Prueba pequeña para decidir entre Python y Godot (ver `docs/motor.md`). **Es solo un
experimento**: el juego sigue siendo el prototipo en Python de la raíz del repositorio.

## Qué hay

Un estante con la manzana y dos amigas (Gala y Aida). Con **flechas o WASD** te mueves;
cerca de una amiga aparece "Z: hablar" y con **Z / Enter / Espacio** se abre el diálogo
estilo Undertale (efecto de escritura, pausas `{pause=...}`, quién habla, completar con la
misma tecla). Un contador de banderas muestra con quién hablaste.

Los textos se leen de `../data/dialogues.json` (`acto1_gala`, `acto1_aida`), los mismos
del prototipo Python y sin modificarlos. Si no se encuentra el archivo, usa textos de
muestra y avisa en la consola.

## Cómo probarlo

1. Instala **Godot 4.3 o más nuevo** (versión estándar, no .NET).
2. Abre Godot → *Importar* → elige `godot/project.godot` → *Ejecutar* (F5).
3. Sigue el checklist de `docs/motor.md` (sección 4).

## Estado

La base (movimiento, diálogo, lectura de `dialogues.json` y exportación a Linux) fue probada
por el equipo y funciona. **Sin probar todavía:** la carga de sprites desde `sprites/` y la
carpeta `data/` junto al ejecutable (se agregaron después). Si algo falla, copia el mensaje
de la consola de Godot.

## Pruebas

Etapa 0 de la migración (`docs/migracion-godot.md`). Se corren desde la raíz del repositorio:

```
godot --headless --path godot --script res://tests/run_tests.gd
```

Termina con código 1 si algo falla. Si Godot no encuentra un `class_name` nuevo, corre antes una vez
`godot --headless --path godot --import`. Los tests viven en `tests/test_*.gd`; los valores que
comparan los calcula Python y están en `tests/golden/` (se regeneran con
`python tools/export_golden.py`; un test de Python avisa si quedaron viejos).

**Sin ejecutar todavía:** el ejecutor y los tests de Godot se escribieron sin poder correr Godot.

## Arte

Para cambiar los dibujos de formas por arte real, basta dejar PNG en `sprites/` (ver
`sprites/LEEME.md`: nombres, tamaño de 32 × 32 y cómo verlo). El juego los lee en tiempo
de ejecución, sin importar nada en Godot; también funciona con la versión exportada si hay
una carpeta `sprites/` junto al ejecutable. De la misma forma, una carpeta `data/` junto al
ejecutable se usa antes que `../data`.

## Archivos

| Archivo | Qué hace |
|---|---|
| `scripts/main.gd` | Sala, paredes, acciones de teclado, interacción y banderas |
| `scripts/player.gd` | Movimiento de la manzana |
| `scripts/npc.gd` | Una fruta hablante |
| `scripts/sprites.gd` | Carga de PNG por nombre desde `sprites/` (con respaldo a figuras) |
| `scripts/dialogue_parser.gd` | Parseo de `{pause=...}` y líneas (equivale a `dialogue/text.py`) |
| `scripts/dialogue_box.gd` | Caja de diálogo con máquina de escribir |
