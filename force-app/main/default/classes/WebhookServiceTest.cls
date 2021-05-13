/**
 * Description: Test class for WebhookService class.
 */
@IsTest
private class WebhookServiceTest {
    
    private static final String PATH = '/services/apexrest/v1/WebhookService/';
    private static final WebhookAuthToken__mdt AUTH = WebhookAuthToken__mdt.getInstance('WebhookTestToken');
    private static final String EVENT_NAME = 'WebhookTestEvent';

    @IsTest
    static void handlePostTest_WebhookTestEvent() {

        

        RestResponse response = new RestResponse();
        RestRequest request = new RestRequest();

        request.requestUri = PATH + EVENT_NAME; 
        request.addParameter('token', AUTH.Token__c);
        request.addParameter('username', AUTH.Username__c);
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{ "payload" : "DummyData" }');
        
        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        WebhookService.handlePost();
        Test.stopTest();

        System.assertEquals(
            202, 
            RestContext.response.statusCode,
            'Rest response status code is not successful.'
        );
    }

    @IsTest
    static void handlePostTest_UnauthorizedRequest() {

        RestResponse response = new RestResponse();
        RestRequest request = new RestRequest();

        request.requestUri = PATH; 
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        
        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        WebhookService.handlePost();        
        Test.stopTest();

        System.assertEquals(
            401, 
            RestContext.response.statusCode,
            'Rest response status code does not match the expected value.'
        );
    }

    @IsTest
    static void handlePostTest_InvalidEvent() {
        
        String eventName = '_InvalidEvent_';

        RestResponse response = new RestResponse();
        RestRequest request = new RestRequest();
        request.requestUri = PATH + eventName;
        request.addParameter('token', AUTH.Token__c);
        request.addParameter('username', AUTH.Username__c);
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        
        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();
        
        WebhookService.handlePost();
        Test.stopTest();

        System.assertEquals(
            500, 
            RestContext.response.statusCode,
            'Rest response status code does not match the expected value.'
        );

        System.assert(
            RestContext.response.responseBody.toString().containsIgnoreCase('Event not found'),
            'Rest response is expected to contain error message: Event not found.'
        );
    }
}
