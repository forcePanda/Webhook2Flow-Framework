/**
 * Description: Handler class to orchestrate the incoming Webhook events from Echonovum.
 */
public inherited sharing class WebhookServiceHandler {
    
    public final Integer INTERNAL_SERVER_ERROR = 500;
    public final Integer UNAUTHORIZED = 401;
    public final Integer ACCEPTED = 202;

    private final String PARAM_TOKEN = 'token';
    private final String PARAM_USERNAME = 'username';

    private RestRequest request;
    private WebhookServiceResponse response;
    private Webhook2FlowHandler__mdt event2FlowConfig {
        get {
            if(event2FlowConfig == null) {
                event2FlowConfig = Webhook2FlowHandler__mdt.getInstance(
                    getWebhookEvent()
                );

                if(event2FlowConfig == null) {
                    throw new WebhookServiceHandlerException('Event not found. Check CMDT mappings.');
                }
            }
            return event2FlowConfig;
        }
        set;
    }

    public WebhookServiceHandler(RestRequest request) {
        this.response = new WebhookServiceResponse();
        this.request = request;
    }

    /**
     * Method to check if the incoming webhook event request is coming from an authorized source.
     * The request parameters are matched against tokens stored in WebhookAuthToken__mdt.
     */
    public Boolean isAuthorized() {

        if(this.request.params.get(this.PARAM_TOKEN) == null || this.request.params.get(this.PARAM_USERNAME) == null) {
            return false;
        }

        return this.request.params.get(this.PARAM_TOKEN) == WebhookAuthToken__mdt.getInstance(this.request.params.get(this.PARAM_USERNAME)).Token__c;
    }

    /**
     * Main method to handle the incoming webhook event request.
     * Method invokes the corresponding handler flow for the incoming webhook event.
     */
    public void handlePostRequest() {

        Flow.Interview flowHandler = Flow.Interview.createInterview(
            this.event2FlowConfig.FlowAPIName__c, 
            this.getFlowInputs()
        );

        flowHandler.start();

        /**
         * Can be further extended to send some data back as response by
         * getting value from flow O/P variables.
         */

        this.setSuccessResponse(this.ACCEPTED, null);
    }

    /**
     * Method to set the error response for current HTTP request when there is an exception.
     */
    public void setErrorResponse(Exception ex) {

        this.response.data = null;
        this.response.error = new ErrorResponse(ex.getTypeName(), ex.getMessage());

        RestContext.response.responseBody = this.getResponseBodyAsBlob();
        RestContext.response.statusCode = this.INTERNAL_SERVER_ERROR;
    }

    /**
     * Method to set the success response for the current HTTP request.
     */
    public void setSuccessResponse(Integer statusCode, Object data) {

        RestContext.response.statusCode = statusCode;
        this.response.data = data;
    }

    /**
     * Method to set the input variable of the Webhook event handler flow.
     */
    private Map<String,Object> getFlowInputs() {

        Map<String,Object> flowInputs = new Map<String,Object>();

        flowInputs.put(
            event2FlowConfig.FlowInputVariableName__c,
            JSON.deserialize(this.request.requestBody.toString(), Type.forName(event2FlowConfig.EventDefnApexClass__c))
        );
        return flowInputs;
    }

    /**
     * Method to convert request's response into Blob.
     */
    private Blob getResponseBodyAsBlob() {
        return Blob.valueOf(JSON.serialize(this.response));
    }

    /**
     * Method to return the name of incoming webhook event.
     * Example: /v1/WebhookService/DummyEvent?token=123 => DummyEvent
     */
    private String getWebhookEvent() {
        return request.requestURI.removeEnd('/').substringAfterLast('/').substringBefore('?');
    }

    /**
     * Class to define response structure for incoming webhook requests.
     */
    public class WebhookServiceResponse {
        public Object data;
        public Object error;
    }

    /**
     * Class to define error response structure for incoming webhook requests.
     */
    public class ErrorResponse {
        public String code;
        public String message;

        public ErrorResponse(final String code, final String message) {
            this.code = code;
            this.message = message;
        }
    }

    public class WebhookServiceHandlerException extends Exception {}
}
