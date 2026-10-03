# ForestApple — Documento de diseño

> Versión 0.1. Las secciones marcadas **[Decidido]** vienen del equipo.
> Las marcadas **[Propuesta]** son ideas para discutir: se aceptan, se cambian o se tiran.

## 1. Premisa [Decidido]

Una manzana toma conciencia de sí misma al ver cómo su familia es desperdiciada
(no comida, sino dejada pudrir). Entra en una crisis existencial: ¿qué prefiere,
ser comida o pudrirse? Decide que su propósito es **volverse un bosque de manzanos**
(no un solo árbol): sacrificar todo su cuerpo y morir podrida para ser el sustrato
perfecto, lleno de nutrientes, que sus semillas necesitan.

Como una manzana no puede hacer mucho contra las personas, se alía con un niño
cuya imaginación le permite comunicarse con ella. Quiere que las demás frutas la
ayuden, pero ellas creen que delira: están convencidas de que al ser comidas van
al "cielo de las frutas" (falso). Estalla la **guerra civil de las frutas**. La
manzana desciende por la heladera enfrentándose a cada una. Al final, el niño
pelea contra su familia, gana, se despide de la manzana, la entierra y crece el
bosque.

**Tema central:** ¿es mejor dar la vida por otro (ser comido) o por algo que
continúa (pudrirse para dar vida)? Ninguna de las dos respuestas es gratis.

## 2. Personajes

| Personaje | Rol | Estado |
|---|---|---|
| **Manzana** | Protagonista jugable. Consciente, obsesiva con su plan, con trauma familiar. | Decidido |
| **El niño** | Aliado jugable. Su **nombre nunca se dice**; la manzana lo llama "niño". Aparece en miniatura, igual que las frutas, por su imaginación. | Decidido |
| **Juan** | Hermano mayor del niño. Jefe final (con sus padres). | Decidido |
| **María y Adán** | Padres del niño. Jefes finales. | Decidido |
| **Las frutas** | Frutilla, piña, sandía, durazno, banana, limón. Enemigos de la guerra civil. | Decidido |

Los adultos se ven **gigantes** para las frutas y el niño en miniatura. Eso es
también una decisión visual: ellos nunca se ven enteros, solo manos, sombras,
pies o partes (**[Propuesta]**, ahorra arte y refuerza la escala).

**Pregunta abierta:** ¿por qué la familia es hostil con el niño? Alcanza con una
línea sugerida en el Acto 1 ("nadie lo escucha porque se imagina cosas"), pero
conviene fijarlo antes de escribir diálogos.

## 3. Estructura en tres actos [Decidido]

Cada acto tiene un estilo de juego distinto.

### Acto 1 — Introducción (estilo Undertale)
- Exploración libre, sin combate. Se camina por los estantes y se **habla con
  otras frutas**.
- Se muestra la vida de la manzana, su trauma y su crisis.
- El niño aparece y se forma la alianza.
- Las frutas expresan su fe en el cielo de las frutas (siembra el conflicto).

### Acto 2 — La guerra civil (estilo Isaac)
- Es lo que ya está hecho: salas, puertas, enemigos, jefe por piso.
- Se **desciende por la heladera**, de estante en estante.
- El niño acompaña en miniatura como **apoyo**: cura o hace de escudo/tanque.
- Las frutas derrotadas mueren, pero la manzana **se lleva dos semillas de cada
  una** para plantarlas junto a ella al final.
- Antes de cada pelea importante puede haber un diálogo tipo Undertale
  (las frutas defienden sus creencias).

### Acto 3 — Batalla final (jugamos como el niño)
- El niño pelea contra Juan, María y Adán.
- Gana, se despide de la manzana, la entierra y crece el bosque (final bonito).

**Pregunta abierta:** ¿cómo se juega la batalla final? Opciones: (a) el mismo
estilo Isaac pero con el niño y sus propias reglas, (b) un jefe con tres fases,
una por familiar, (c) algo más narrativo y menos de combate. Para el MVP
conviene la (b) con el sistema que ya existe.

## 4. Mecánicas

### Ya decidido
- Controles: movimiento con WASD, disparo con flechas, una sala a la vez.
- El niño como apoyo: curación o escudo.
- Algunas frutas podrán volverse **ítems acompañantes** (como en Isaac) que
  disparan o curan. *(Futuro)*
- **Ruta pacifista**: convencer a la mayor cantidad de frutas posible. *(Futuro)*

### Propuestas
- **La vida como podredumbre:** en vez de corazones, el cuerpo de la manzana se
  ve cada vez más podrido a medida que recibe daño. Refuerza el tema.
- **Semillas como recurso:** las dos semillas por fruta derrotada se cuentan en
  pantalla y definen cómo luce el bosque del final.
- **Pisos por estante (ejemplo):** estante superior → estante medio → cajón de
  verduras → fondo. Cada piso con 5-6 salas y un jefe.

## 5. Enemigos (Acto 2)

| Fruta | Comportamiento |
|---|---|
| **Frutilla** | Frágil, dispara semillas. *(Hecha)* |
| **Piña** | Tanque: mucha vida, lenta. |
| **Banana** | Guardia que ataca cuerpo a cuerpo. |
| **Durazno** | Rueda hacia el jugador. |
| **Limón** | Lanza ácido. |
| **Sandía** | Jefe. |

## 6. Alcance

**MVP (primero):**
1. Acto 2 jugable con un piso completo: salas, 3 enemigos, 1 jefe.
2. Sistema de diálogo estilo Undertale (caja de texto, máquina de escribir).
3. Acto 1 mínimo: una sola escena caminable con 2-3 frutas que hablan.
4. Acto 3 mínimo: un jefe con tres fases y el final.

**Después:** más pisos, niño como apoyo con habilidades, ítems-fruta, ruta
pacifista, arte y música finales.

## 7. Implicaciones técnicas

- El juego necesita **estados** (exploración, combate, batalla final, diálogo),
  porque cada acto se juega distinto. Hoy solo existe el modo combate.
- El sistema de diálogo pasa a ser clave desde temprano: lo usan el Acto 1, las
  peleas del Acto 2 y el final.
- Los textos van en `data/` (JSON) para que quien escriba no toque código.

## 8. Preguntas abiertas (resumen)

1. ¿Por qué la familia es hostil con el niño?
2. ¿Cómo se juega la batalla final del niño?
3. ¿Qué tan largo es el Acto 1 en el MVP?
4. ¿Qué relación tiene el niño con las frutas antes de conocer a la manzana?
5. ¿Qué pasa con las semillas llevadas de cada fruta en el final?
