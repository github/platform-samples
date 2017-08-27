# GitHub API Challenge


This is simple web service that listens for repository events to know when a repository has been deleted. When the repository is deleted a new issue is created in the cls_notification repository that notifies chadlsmith of the deletion event. 


### Prerequisites
* [Ngrok ](https://ngrok.com/download) 
* [Ruby 2.2 or higher](https://www.ruby-lang.org/en/downloads/) 
* [Sinatra](https://github.com/sinatra/sinatra) 
* A git client which is included with most modern operating systems
* [API Token](https://github.com/blog/1509-personal-api-tokens) 

### Configuration   

Before running the sample, you will need to start the following services on your machine.

#### Ngrok 
To start ngrok run the following command 

```
<ngrok_download_dir> /ngrok http 4567
```

When ngrok starts take note of the forwarding ip address it will be similar to:

```
Forwarding                    http://4554ee82.ngrok.io -> localhost:4567
```
#### Clone repository

To pull the most recent version of the sample run a git clone on the clsOrg/platform-samples repository 
```
git clone https://github.com/clsOrg/platform-samples.git
```

#### Start Application

To setup the environment to connect to your GitHub Org you will need to **update the set.env file with your api key** and execute the set.env file using the following command:

```
. ./<sample_install_dir>/platform-samples/hooks/ruby/delete-repository-event/set.env
```

To start the the samples run the following command:

```
ruby <sample_install_dir>/platform-samples/hooks/ruby/delete-repository-event/app.rb
```


## Running the test

* [Create a webhook with the following settings:](https://developer.github.com/webhooks/creating/)  
  * Payload URL = Forwarding link from ngrok with a trailing /delete-repository-event
    ```
    http://4554ee82.ngrok.io/delete-repository-event
    ```
  * Content Type = json 
  * Which events would you like to trigger this webhook = Let me select individual events
    * Repository
* [Create a sample repository:](https://help.github.com/articles/create-a-repo/)  
* [Delete the newly created repository:](https://help.github.com/articles/deleting-a-repository/)  

## Validating the test

Go to  https://github.com/clsOrg/cls_notification to validate that a new issue has been created. It should be smiilar to example below.  

```
[Restore the repository](https://github.com/stafftools/users/clsOrg/purgatory)
 @chadlsmith Please review this isue
```json
{
  "action": "deleted",
  "repository": {
    "id": 101403334,
    "name": "tets1",
    "full_name": "clsOrg/tets1",
    "owner": {
      "login": "clsOrg",
      "id": 31157515,
...

```

## Debugging 
If your issue was not created you can debug using the following steps: 

* Was the webhook created? 
  * You can verify the webhook ran by checking recent deliveries https://github.com/organizations/clsOrg/settings/hooks/15740340
* Did ngrok recognize the webhook 
  * In the ngrok console you should see a new HTTP request 
    ```
     HTTP Requests
     -------------

     POST /delete-repository-event  201 Created
     ```
* Did the the application event fire? 
   ```
   127.0.0.1 - - [25/Aug/2017:04:48:31 UTC] "POST /delete-repository-event HTTP/1.1" 500 0
   ```


## Built With
The example is based on the platform samples provided on github.com
* [platform-samples](https://github.com/github/platform-samples/tree/master/hooks/ruby/delete-repository-event/) 
