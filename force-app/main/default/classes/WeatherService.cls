public without sharing class WeatherService {
    @AuraEnabled(cacheable=false)
    public static string getWeather(string location) {

        //Retrieve endpoint data from CMDT        
        Weather_Settings__mdt ws = Weather_Settings__mdt.getInstance('Weather_API');
        string baseURL = string.valueOf(ws.Endpoint__c);                
        string apiKey = string.valueOf(ws.API_Key__c);
        string endpoint = baseURL + '?key=' + apiKey + '&q=' + location;

        // Set up HTTP request
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setTimeout(120000); 

        // Send HTTP request
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            string result = response.getBody();
            system.debug(result);
            return result;
        } else {
            string errorResult = response.getBody();
            return errorResult; 
        }
    }
}