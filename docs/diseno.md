# ForestApple — Documento de diseño

> Versión 0.2. Las secciones marcadas **[Decidido]** vienen del equipo.
> Las marcadas **[Propuesta]** son ideas para discutir: se aceptan, se cambian o se tiran.

## 1. Premisa [Decidido]

Una manzana toma conciencia de sí misma al ver cómo sus amigas, otras manzanas,
son desperdiciadas (no comidas, sino dejadas pudrir). Entra en una crisis existencial: ¿qué prefiere,
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
| **Manzana** | Protagonista jugable. Consciente, obsesiva con su plan, marcada por la pérdida de sus amigas. | Decidido |
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
- Exploración libre, sin combate, como un RPG: se ve **un poco de la vida de la
  manzana**, se camina por los estantes y se **habla con otras frutas**.
- Hay **mini-tareas cortas** (nada extenso) hasta que ocurre el **hecho trágico**:
  mueren sus **amigas, otras manzanas** (no su familia). De ahí sale su crisis.
- Las frutas expresan su fe en el cielo de las frutas (siembra el conflicto).
- El niño aparece y se forma la alianza.

#### Esquema del Acto 1 [Propuesta]

Para que la pérdida duela, el Acto 1 tiene que hacer que **se quiera a las amigas**
antes de perderlas. Son pocas y distintas entre sí, y cada mini-tarea le muestra al
jugador a una de ellas (y a una fruta de otra especie) y siembra un tema.

**Las amigas** (los nombres son de relleno):

| Amiga | Cómo es | Qué siembra |
|---|---|---|
| **Manzana vecina A** | Creyente: está feliz de que algún día la coman. | La fe en el cielo de las frutas. |
| **Manzana vecina B** | Duda en silencio, pregunta cosas que nadie contesta. | Que la protagonista no es la única que se pregunta. |
| **Manzana vecina C** | Solo quiere un día tranquilo; la más cálida. | Lo que se pierde: la vida cotidiana. |

**Momentos** (unas 5 a 6 pantallas y 15 a 20 minutos de calma):

1. **Un día cualquiera.** Despertar en el estante, conocer el lugar y a las vecinas. Se aprenden los controles caminando y hablando.
2. **Mini-tareas** (3 o 4, de pocos minutos cada una). Ideas: llevar un mensaje a una fruta de otro estante, encontrar algo que se le perdió a una vecina, ayudar a una banana con un problema cotidiano. Cada una deja un rato de conversación sobre el cielo de las frutas.
3. **Un día de más calma que de costumbre.** Un cierre cálido (una charla entre las tres) justo antes del golpe.
4. **El hecho trágico.** Las amigas desaparecen del estante y la manzana ve qué pasó: las tiran o las dejan pudrir sin que nadie las coma. La escena es corta y se juega, no solo se lee.
5. **La crisis.** Un rato de exploración con los mismos lugares vacíos y las otras frutas actuando como si nada. Las frutas no le creen; la manzana toma conciencia y decide su plan (volverse un bosque).
6. **El niño** aparece y se forma la alianza. Se abre el Acto 2.

**Decisiones que faltan antes de escribir diálogos:**
- Cómo se ve el hecho trágico (qué ve exactamente la manzana).
- Si el niño aparece antes del hecho (como una presencia rara) o recién después.
- Si las mini-tareas se pueden hacer en cualquier orden.

### Acto 2 — La guerra civil (estilo Isaac)
- Es lo que ya está hecho: salas, puertas, enemigos, jefe por piso.
- Se **desciende por la heladera**, de estante en estante.
- El niño acompaña en miniatura como **apoyo**: cura o hace de escudo/tanque.
- Cada piso del acto 2 tendrá **ítems/trinkets** que mejoran a la manzana. Se
  muestran con su sprite debajo del minimapa, como en *The Binding of Isaac*.
  El primer trinket es una llave consumible para entrar a la sala de la sandía;
  todavía no hay mejoras permanentes para la manzana.
- Al derrotar al jefe aparece un agujero en el centro de la sala. Al acercarse
  y pulsar `E`, la pantalla se oscurece y aparece un diálogo sin nombre que dice
  «La batalla continuará...». El piso 2 todavía no está hecho.
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

## 5. Acto 2: piso 1 y enemigos

El piso 1 es una grilla conectada de ocho salas: una inicial, seis normales y
la sala del jefe. Las puertas se cierran durante los combates y las salas
limpias permanecen limpias al volver. La sandía queda inaccesible hasta limpiar
todas las demás salas. Al completar la última, aparece una llave plateada
provisoria en el centro de esa sala. La manzana debe acercarse y pulsar `E` para
recogerla; luego se usa con `E` junto a la puerta de la sandía y desaparece al
abrirla. La puerta cerrada con llave se distingue por su color plateado. Al
derrotar a la sandía aparece el agujero de salida; al pulsar `E` junto a él se
oscurece la pantalla y aparece un diálogo sin nombre: «La batalla continuará...».
El descenso al piso 2 aún no está conectado.

El inventario de trinkets aparece debajo del minimapa y admite mostrar varios
iconos. Todo el acto 2 tendrá trinkets que mejoren a la manzana; por ahora la
llave de acceso es el único implementado y no otorga una mejora de combate.

### Enemigos

| Fruta | Comportamiento |
|---|---|
| **Frutilla** | Frágil, dispara semillas. *(Hecha)* |
| **Piña** | Tanque: mucha vida, lenta. |
| **Banana** | Guardia que ataca cuerpo a cuerpo. |
| **Durazno** | Rueda hacia el jugador. |
| **Limón** | Lanza ácido. |
| **Sandía** | Jefe del piso 1, tres fases. *(Hecha, sin balancear)* |

### Sandía (jefe del piso 1) [Implementada]

No pelea por odio sino por **fe**: quiere convencer a la manzana de que ser
comido lleva al cielo de las frutas. Las tres fases van de predicar, a perder la
paciencia, a ofrecerse a ser comida. Tiene cientos de semillas y la manzana se
lleva solo dos de ella: contraste que se puede usar en el final.

| Fase | Vida | Qué hace |
|---|---|---|
| 1 | 100 % a 66 % | Camina lento y escupe abanicos de 5 semillas. |
| 2 | 66 % a 33 % | Se sacude (aviso), rueda rebotando 3 veces y queda aturdida (doble daño). |
| 3 | 33 % a 0 % | Es más rápida; alterna abanicos y espirales y deja charcos de jugo que dañan. |

Entre fases se frena la pelea y habla (diálogo, hoy provisorio en
`data/dialogues.json`). Al morir dice sus últimas palabras y recién después
aparece el aviso de piso completado. Los números son provisorios.

## 6. Estado del demo

El primer demo se concentra en completar el piso 1 del acto 2: ocho salas,
cinco tipos de enemigos regulares, la sandía con tres fases, diálogos
provisorios, llave de acceso y salida visual hacia el piso 2. Hay movimiento,
disparo, minimapa, puertas, pausa y HUD. El balance, arte, música y diálogos
siguen siendo provisionales.

Acto 1, acto 3, más pisos y trinkets que den mejoras a la manzana siguen para
más adelante. El sistema muestra los trinkets y soporta la llave consumible; aún
no existen mejoras de combate.

## 7. Implicaciones técnicas

- El juego necesitará **estados** (exploración, combate, batalla final,
  diálogo), porque cada acto se juega distinto. Hoy está implementado el piso
  de combate del acto 2 y la caja provisoria de diálogo.
- El sistema de diálogo pasa a ser clave desde temprano: lo usan el Acto 1, las
  peleas del Acto 2 y el final.
- Los textos van en `data/` (JSON) para que quien escriba no toque código.
- El Acto 1 necesita **banderas de historia** (qué tareas se hicieron, con quién se habló) y NPCs con diálogos que cambian según eso. Hoy no existe.

### Motor: Python y Godot [Propuesta]

El prototipo actual está en Python (pygame) y no hay obligación de seguir con él.
El Acto 1 es un RPG de exploración (mapas, NPCs, zonas que disparan eventos,
cinemáticas), justo lo que más cuesta a mano y más resuelve un motor con editor.
Propuesta:

- Hacer en **Godot** un recorte pequeño del Acto 1 (una sala con dos NPCs y un
  diálogo) y decidir con eso en la mano. Si no convence, el prototipo en Python
  sigue intacto.
- No borrar el repositorio actual: queda como prototipo y referencia del Acto 2.
- Se conservan los diseños y los JSON (`rooms`, `enemies`, `dialogues`); lo que
  hay que reescribir es el código.
- Quien hace el arte puede trabajar directo en Godot (importar sprites, animar, armar
  mapas), y el soporte para Android pasa a ser el oficial.

Esto **no está decidido**: depende de probar el recorte.

## 8. Preguntas abiertas (resumen)

1. ¿Por qué la familia es hostil con el niño?
2. ¿Cómo se juega la batalla final del niño?
3. ¿Qué tan largo es el Acto 1 en el MVP? (Propuesta: 15 a 20 minutos.)
4. ¿Qué relación tiene el niño con las frutas antes de conocer a la manzana?
5. ¿Qué pasa con las semillas llevadas de cada fruta en el final?
6. ¿Cómo se ve el hecho trágico del Acto 1 y cuándo aparece el niño?
7. ¿Seguimos en Python o pasamos a Godot? (Depende del recorte de prueba.)
