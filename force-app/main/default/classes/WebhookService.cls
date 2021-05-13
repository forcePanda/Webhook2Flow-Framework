/**
 * Description: Apex class as a custom webservice to handle incoming Webhook events.
 */
@RestResource(urlMapping='/v1/WebhookService/*')
global inherited sharing class WebhookService {

    private static WebhookServiceHandler handler;
    
    /**
     * Entry method for all the 'POST' requests.
     */
    @HttpPost
    global static void handlePost() {

        handler = new WebhookServiceHandler(RestContext.request);

        if(!handler.isAuthorized()) {
            RestContext.response.statusCode = handler.UNAUTHORIZED;
            return;
        }

        try {
            handler.handlePostRequest();
        } catch (Exception ex) {

            System.debug(ex);
            handler.setErrorResponse(ex);
        }
    }
}
