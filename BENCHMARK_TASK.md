Trabaja directamente sobre este repositorio.

Implementa un modelo JPA en Spring Boot 3 y Java 21 para gestionar
libros y autores.

Un autor tiene:
- id
- nombre
- apellidos
- edad

Un libro tiene:
- id
- título
- descripción

La relación es muchos a muchos.

Crea:
- entidades JPA
- repositorios
- servicio
- tests JUnit 5

Los tests deben comprobar:
- crear y persistir un libro con varios autores
- recuperar desde la base de datos los títulos de los libros de un autor

Restricciones:
- no añadas controladores REST
- no uses Lombok
- usa jakarta.persistence
- evita CascadeType.ALL en la relación muchos a muchos
- los tests deben hacer flush y clear para comprobar persistencia real
- no te limites a mostrar código en el chat: modifica los archivos
- ejecuta ./mvnw test
- analiza los fallos y corrige el proyecto hasta que todos los tests pasen
- no termines hasta que la compilación y los tests estén verdes
- no modifiques archivos ajenos al objetivo
-  No ejecutes comandos que creen, modifiquen o eliminen archivos
-  fuera del directorio de trabajo actual. No uses sudo.
