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

## Estado: sin verificar

Lo escribí sin poder ejecutar Godot (no pude obtener el binario), así que **puede tener
errores** de sintaxis o de API. Si algo falla, copia el mensaje de la consola de Godot y
se corrige. No se usa ninguna imagen: todo se dibuja con formas para no depender de
archivos importados. El dibujo de la manzana y las frutas está en `_draw()` y se
reemplaza por sprites cuando haya arte.

Como la ruta `../data` solo funciona al ejecutar desde el editor, una versión exportada
necesitaría copiar los JSON dentro del proyecto (no está resuelto).

## Archivos

| Archivo | Qué hace |
|---|---|
| `scripts/main.gd` | Sala, paredes, acciones de teclado, interacción y banderas |
| `scripts/player.gd` | Movimiento de la manzana |
| `scripts/npc.gd` | Una fruta hablante |
| `scripts/dialogue_parser.gd` | Parseo de `{pause=...}` y líneas (equivale a `dialogue/text.py`) |
| `scripts/dialogue_box.gd` | Caja de diálogo con máquina de escribir |
