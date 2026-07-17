# REGLAS DEL AGENTE

- Trabaja exclusivamente dentro del repositorio actual.
- No uses sudo, apt, curl ni wget.
- No instales ni descargues Java, Maven u otras herramientas.
- Java 21 y Maven ya están instalados globalmente.
- Usa `mvn test` para validar.
- Maven puede descargar las dependencias declaradas en el pom.xml.
- Crea el proyecto Spring Boot completo desde cero.
- No modifiques AGENTS.md ni BENCHMARK_TASK.md.
- Si java, javac o mvn no están disponibles, detente y explica el bloqueo.
- No hagas push, merge, rebase ni cambies de rama.

Haz commits por unidades lógicas:

1. estructura y pom.xml;
2. entidades;
3. repositorios y servicio;
4. tests;
5. correcciones finales.

Antes de cada commit ejecuta `git status --short`.
No declares la tarea terminada hasta obtener `BUILD SUCCESS`.
