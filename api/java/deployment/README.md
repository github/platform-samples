# DeployServer

A sample implementation for using GitHub Deployment API.

Ported [this](https://developer.github.com/guides/delivering-deployments/) by Java. Powered by [Spark](http://sparkjava.com/).

## Prerequisite
- JDK8
- Maven3
- GitHub OAuth Token

## Getting Started
First, you should set your OAuth token into an environment variable somewhere, like:
```
export GITHUB_OAUTH=xxxxxxx
```

After that, you can:

- For development

```
$ mvn compile exec:java
```

If you aren't familiar with CLI, you can just run the main class via an execution button in your IDE as well.

- For deployment

```
$ mvn clean package
$ java -jar target/DeployServer-{version}.jar
```

Then you can see it works on `http://localhost:4567`.

After you make sure this sever deployed a place where GitHub can reach out to, you can test how it interacts with GitHub via its Deployment API.

You can also place it on your local pc, then expose it by using ngrok. Please refer the direction described [here](https://developer.github.com/guides/delivering-deployments/).
