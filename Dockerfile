FROM gradle:8-jdk21 AS builder

WORKDIR /workspace

COPY build.gradle settings.gradle gradlew gradlew.bat ./
COPY gradle ./gradle
COPY src ./src

RUN gradle --no-daemon bootJar -x test

FROM eclipse-temurin:21-jre

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /workspace/build/libs/*.jar /app/mywebapp.jar

EXPOSE 5200

ENTRYPOINT ["java", "-jar", "/app/mywebapp.jar"]
