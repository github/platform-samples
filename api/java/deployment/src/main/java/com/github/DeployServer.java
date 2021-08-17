package com.github;

import com.google.gson.Gson;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import org.kohsuke.github.*;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import static org.kohsuke.github.GHDeploymentState.PENDING;
import static org.kohsuke.github.GHDeploymentState.SUCCESS;
import static spark.Spark.*;

/**
 * Hello world!
 */
public class DeployServer {
    public static void main(String[] args) {

        get("/", (req, res) -> "Deploy Server");

        get("/hello", (req, res) -> "Hello World");

        post("/event_handler", (req, res) -> {
            String payload = req.body();
            String x_github_event = req.headers("X-GITHUB-EVENT");

            Gson gson = new Gson();
            JsonObject jsonObject = gson.fromJson(payload, JsonElement.class).getAsJsonObject();

            switch (x_github_event) {
                case "pull_request":
                    if ("closed".equalsIgnoreCase(jsonObject.get("action").getAsString()) &&
                            jsonObject.get("pull_request").getAsJsonObject().get("merged").getAsBoolean()) {

                        System.out.println("A pull request was merged! A deployment should start now...");

                        start_deployment(jsonObject.get("pull_request").getAsJsonObject());
                    }
                    break;
                case "deployment":
                    process_deployment(jsonObject);
                    break;
                case "deployment_status":
                    update_deployment_status(jsonObject);
                    break;
            }

            return "Well Done!!!!!";
        });
    }


    private static void start_deployment(JsonObject jsonObject) {
        String user = jsonObject.get("user").getAsJsonObject().get("login").getAsString();
        Map<String, String> map = new HashMap<>();
        map.put("environment", "QA");
        map.put("deploy_user", user);
        Gson gson = new Gson();
        String payload = gson.toJson(map);

        try {
            GitHub gitHub = GitHubBuilder.fromEnvironment().build();
            GHRepository repository = gitHub.getRepository(
                    jsonObject.get("head").getAsJsonObject()
                            .get("repo").getAsJsonObject()
                            .get("full_name").getAsString());
            GHDeployment deployment =
                    new GHDeploymentBuilder(
                            repository,
                            jsonObject.get("head").getAsJsonObject().get("sha").getAsString()
                    ).description("Auto Deploy after merge").payload(payload).autoMerge(false).create();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private static void process_deployment(JsonObject jsonObject) {
        String payload_str = jsonObject.get("deployment").getAsJsonObject().get("payload").getAsString();
        Map payload = new Gson().fromJson(payload_str, Map.class);

        System.out.println("Processing " + jsonObject.get("deployment").getAsJsonObject().get("description").getAsString() +
                " for " + payload.<String>get("deploy_user") + " to " + payload.<String>get("environment"));

        try {
            Thread.sleep(2000L);
            GitHub gitHub = GitHubBuilder.fromEnvironment().build();
            GHRepository repository = gitHub.getRepository(
                    jsonObject.get("repository").getAsJsonObject()
                            .get("full_name").getAsString());
            GHDeploymentStatus deploymentStatus = new GHDeploymentStatusBuilder(repository,
                    jsonObject.get("deployment").getAsJsonObject().get("id").getAsInt(), PENDING).create();
            Thread.sleep(5000L);

            GHDeploymentStatus deploymentStatus2 = new GHDeploymentStatusBuilder(repository,
                    jsonObject.get("deployment").getAsJsonObject().get("id").getAsInt(), SUCCESS).create();
        } catch (IOException e) {
            e.printStackTrace();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

    }


    private static void update_deployment_status(JsonObject jsonObject) {
        System.out.println("Deployment status for " + jsonObject.get("deployment").getAsJsonObject().get("id").getAsString() +
                " is " + jsonObject.get("deployment_status").getAsJsonObject().get("state").getAsString());
    }
}
