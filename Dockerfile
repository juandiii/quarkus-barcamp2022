FROM eclipse-temurin:17.0.5_8-jdk-alpine as jre-build

WORKDIR /app

COPY target/lib build/lib
COPY target/app-runner.jar build/app.jar

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
  --add-modules $(cat jre-deps.info),jdk.zipfs

FROM alpine:3.17.0

RUN apk add --no-cache tzdata musl-locales musl-locales-lang dumb-init \
  && rm -rf /var/cache/apk/*

WORKDIR /deployment

COPY --from=jre-build /app/jre jre
COPY --from=jre-build /app/build/lib/* lib/
COPY --from=jre-build /app/build/app.jar app.jar

ENTRYPOINT ["/usr/bin/dumb-init", "--"]


CMD ["jre/bin/java", "-jar", "app.jar"]