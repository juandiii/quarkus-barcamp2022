# Quarkus Project with custom runtime JRE (Java Runtime Environment)

1. Primero ir a `pom.xml` y agregar al final de la linea de un `</plugin/>` 
```xml
<plugin>
<groupId>org.apache.maven.plugins</groupId>
<artifactId>maven-jar-plugin</artifactId>
<configuration>
  <finalName>${project.artifactId}-${project.version}</finalName>
  <archive>
    <manifest>
      <addClasspath>true</addClasspath>
      <mainClass>org.acme.Main</mainClass>
      <classpathPrefix>lib/</classpathPrefix>
    </manifest>
  </archive>
</configuration>
</plugin>
```

2. Despues agregar otro abajo de este 

- Sirve para generar las dependencias y colocarlo en un archivo generado en build
```xml
<plugin>
    <artifactId>maven-dependency-plugin</artifactId>
    <executions>
        <execution>
            <phase>package</phase>
            <goals>
                <goal>copy-dependencies</goal>
            </goals>
            <configuration>
                <outputDirectory>${project.build.directory}/lib</outputDirectory>
            </configuration>
        </execution>
    </executions>
</plugin>
```

3. Luego de colocar estas configuraciones, creamos un archivo `Dockerfile` para crear una imagen

Vamos a poner una imagen que tenga JDK y la versión 17 que es LTS

En mi caso sería Eclipse Temurin (Java 17 y Alpine) 

```Dockerfile 
FROM eclipse-temurin:17.0.5_8-jdk-alpine as jre-build
```

Y escribimos un WORKDIR (Current Working Directory que se llama en Linux)

```Dockerfile
WORKDIR /app
```

Y copiamos las liberias generadas por Maven

```dockerfile
COPY target/lib build/lib
COPY target/app-runner.jar build/app.jar
```

Y luego usaremos la herramienta 

```dockerfile
RUN jdeps \
    --ignore-missing-deps \
    -q \
    --multi-release 17 \
    --print-module-deps \
    --class-path 'build/lib/*' \
    build/app.jar > jre-deps.info
    
RUN jlink --verbose \
  --compress 2 \
  --strip-java-debug-attributes \
  --no-header-files \
  --no-man-pages \
  --output jre \
  --add-modules $(cat jre-deps.info)
```

*En nuestro caso fallará por falta de una librería que se requiere en Quarkus.
Al final de la linea colocaremos una `,jdk.zipfs`*

```dockerfile
FROM alpine:3.17.0

RUN apk add --no-cache tzdata musl-locales musl-locales-lang dumb-init \
&& rm -rf /var/cache/apk/*

WORKDIR /deployment

COPY --from=jre-build /app/jre jre
COPY --from=jre-build /app/build/lib/* lib/
COPY --from=jre-build /app/build/app.jar app.jar

ENTRYPOINT ["/usr/bin/dumb-init", "--"]


CMD ["jre/bin/java", "-jar", "app.jar"]
```


