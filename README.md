# Webhook2Flow Framework

A simple framework to handle incoming webhook events to an public/authenticated endpoint using flows.
<br/><br/>
## Prerequisites
- Understanding of Webhooks
- Understanding of Apex-Defined Data Types(don't be scared, it's very easy to understand)
<br/><br/>
## How to use it?
The whole set up relies on the mappings stored in the Webhook2FlowHandler__mdt custom metadata type. So let's start with that.
<br/><br/>
### Webhook2FlowHandler(CMDT)
This CMDT stores the mappings of incoming Webhook events and their respective handler Flows along with some additional info.

|Field Name |Use 	    
|-|-|
| EventDefnApexClass__c | Name of the Apex class containing the Webhook event's payload definition. |
| FlowAPIName__c | API name of the flow to be invoked when the corresponding webhook event is received. |
| FlowInputVariableName__c | Name of the flow input variable that'll store the webhook event information. <br/> NOTE: Name is case-sensitive. |
| WebhookEventName__c | Name of the webhook event |
<br/>

### Webhook URL Structure

**Webhook URL**: https://orgdomain.com/services/apexrest/v1/WebhookService/<EVENT_NAME>\
?username=`USERNAME`\
&token=`TOKEN`

- Org domain URL: URL can be a site URL or the regular org's domain. Regular org domain would require external system to authenticate with Salesforce first.
- EVENT_NAME: Name of the event. It's up to you what you want to name it.
- USERNAME & TOKEN: Comes from the WebhookAuthToken__mdt. Helps in making sure the event is coming from a trusted source. More info to be followed with a use case.

### Now let's try to understand the usage with the help of an example.

Say, we have an external system called **ForcePanda**. ForcePanda is a blog to which allows admin users to setup webhooks, or in other words set up subscribers for specific webhooks events in the system.\
Subscribers, are the systems, that will receive the information sent via the webhook event.

- publish_post : When a new post is published.
- comment_post : When a new comment is added.
<br/><br/>    
#### Events JSON Structure

1. publish_post
```
    {
        'post_title': '',
        'post_url': '',
        'post_date': ''
    }
```

2. comment_post
```
    {
        'comment_content' : '',
        'comment_date' : '',
        'comment_author_email' : ''
    }
```
<br/>
Now, let's say we want to set up a webhook subscription for `publish_post` event in ForcePanda and run an automation in our Salesforce org every time the specified event occurs. Following will be steps to set up the webhook subscription.\

So let's start by setting up the Salesforce side of things.

1. Create Apex class for Apex Defined Data Type.\
Let's call this class `FP_NewPostEvent`. This is how the class will look like:
```
    public class FP_NewPostEvent {

        @AuraEnabled
        public String post_title;

        @AuraEnabled
        public String post_url;

        @AuraEnabled
        public String post_date;
    }
```
> NOTE: To handle nested JSON, you can create multiple Apex classes for child objects and annotate their declaration with @AuraEnabled in the parent class.

2. Create an AutoLaunched Flow, let's call it `FP_NewPostEventHandler`. In the flow,
    - Create a variable, say `NewPostEvent`, of Apex Defined Type and select `FP_NewPostEvent` class.
    Make sure to mark the variable as 'Available for Input'.
    - Add additional logic; what you want to do with the new event in the flow.
    - Activate the flow.

3. Create Webhook2FlowHandler__mdt type record.
    - MasterLabel : ForcePanda: New Post Event.
    - DeveloperName : FP_NewPostEvent
    - Description__c : Event when a new post is published on the ForcePanda. 
    - EventDefnApexClass__c : FP_NewPostEvent
    - FlowAPIName__c : FP_NewPostEventHandler
    - FlowInputVariableName__c : NewPostEvent
    - WebhookEventName__c : FP_NewPostEvent
> Note: EventDefnApexClass__c and WebhookEventName__c need not be same.

4. Create WebhookAuthToken__mdt record.\
WebhookAuthToken__mdt is used to map tokens(32 char long string) with their respective Users who are subscribed to webhook event endpoint.
This is used to add a check if the incoming is trusted source or not.
    - MasterLabel : ForcePanda.
    - DeveloperName : ForcePanda
    - Description__c : This token is used for subscribing to ForcePanda events.
    - Username__c : ForcePanda
    - Token__c : YzmYqRdYocUU7euWx0pdiV0APmmPyzxc
> NOTE: Token__c is a randomly generated 32 chars long string which is used to authorize requests. Anyone with this token would be able to make requests and invoke the flow. So, keep it safe and do not share it casually. 

5. Set user/profile permissions.\
If the running user is a guest user, make sure to give the it's profile the access to run flows and related Apex class(s): 
    - WebhookService, WebhookServiceHandler(Part of framework)
    - FP_NewPostEvent (Class for Event Definition)

5. Register webhook in the external system(ForcePanda).\
Suppose you want are using a Site with domain url:\
`https://mydomain-developer-edition.cs73.force.com`
<br/><br/>
Then, the url to register as webhook will be:\
`https://mydomain-developer-edition.cs73.force.com/services/apexrest/v1/WebhookService/FP_NewPostEvent?token=YzmYqRdYocUU7euWx0pdiV0APmmPyzxc&username=ForcePanda`
<br/><br/>
## Installation

Package(Unmanaged): https://login.salesforce.com/packaging/installPackage.apexp?p0=04t6F000001ZM2y