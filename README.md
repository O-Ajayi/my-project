### This is a sample project for GitHub Actions using Gradle to build Java App

##### build the project

    ./gradlew build

##### build Docker image called java-app. Execute from root

    docker build -t java-app .

##### push image to repo

    docker tag java-app demo-app:java-1.0
