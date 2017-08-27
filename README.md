# GitHub API Challenge


This is simple web service that listens for repository events to know when a repository has been deleted. When the repository is deleted a new issue is created in the cls_notification repository that notifies chadlsmith of the deletion event. 


### Prerequisites
* [Ngrok ](https://ngrok.com/download) 
* [Ruby 2.2 or higher](https://www.ruby-lang.org/en/downloads/) 
* [Sinatra](https://github.com/sinatra/sinatra) 
* A git client which is included with most modern operating systems
* [API Token](https://github.com/blog/1509-personal-api-tokens) 

### Configuration   

Before running the sample you will need to start the following services on your machine

To start ngrok run the following command 

```
<ngrok download dir> /ngrok http 4567
```

When ngrok startes take note of the forwarding ip address it will be similar to:

```
Forwarding                    http://4554ee82.ngrok.io -> localhost:4567
```

To setup the environment to connect to your GitHub Org you will need to update the set.env file with your api key and execute the set.env file using the following command:

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
* [Create a webhook sample repository:](https://help.github.com/articles/create-a-repo/)  
* [Delete the newly created repository:](https://help.github.com/articles/deleting-a-repository/)  

## Validating the test

Go to  https://github.com/clsOrg/cls_notification to validate that a new issue has been created.  

```
https://github.com/clsOrg/cls_notification/issues/4
```

## Debugging 
If your issue was not created you can debug using the following steps: 

Was the webhook created? 
Did ngrok recognize the webhook 
Did the did 

Add additional notes about how to deploy this on a live system

## Built With
The example is based on the platform samples provided on github.com
* [platform-samples](https://github.com/github/platform-samples/tree/master/hooks/ruby/delete-repository-event/) 
