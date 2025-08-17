@RestResource(urlMapping='/weather/*')
global with sharing class WeatherAPI {
    @HttpGet
    global static void getWeather() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        try {
            // Step 1: Retrieve API key and endpoint from Custom Metadata Type
            Weather_Settings__mdt weatherSettings = [
                SELECT Endpoint__c, API_Key__c
                FROM Weather_Settings__mdt
                LIMIT 1
            ];

            if (weatherSettings == null || String.isBlank(weatherSettings.Endpoint__c) || String.isBlank(weatherSettings.API_Key__c)) {
                res.statusCode = 500;
                res.responseBody = Blob.valueOf(JSON.serialize(new ErrorResponse('Server Error', 'Weather API configuration not found or incomplete')));
                return;
            }

            String WEATHER_API_ENDPOINT = weatherSettings.Endpoint__c;
            String WEATHER_API_KEY = weatherSettings.API_Key__c;

            // Step 2: Validate JWT (assuming Task 4 implementation)
            /*String authHeader = req.headers.get('Authorization');
            if (String.isBlank(authHeader) || !authHeader.startsWith('Bearer ')) {
                res.statusCode = 401;
                res.responseBody = Blob.valueOf(JSON.serialize(new ErrorResponse('Unauthorized', 'Missing or invalid JWT token')));
                return;
            }*/

            /*String jwtToken = authHeader.substring(7); // Remove 'Bearer ' prefix
            if (!validateJWT(jwtToken)) {
                res.statusCode = 401;
                res.responseBody = Blob.valueOf(JSON.serialize(new ErrorResponse('Unauthorized', 'Invalid JWT token')));
                return;
            }*/

            // Step 3: Get city parameter from query string
            String city = req.params.get('city');
            if (String.isBlank(city)) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf(JSON.serialize(new ErrorResponse('Bad Request', 'City parameter is required')));
                return;
            }

            // Step 4: Make HTTP callout to OpenWeatherMap
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            String endpoint = WEATHER_API_ENDPOINT + '?key=' + WEATHER_API_KEY + '&q=' + city;
            request.setEndpoint(endpoint);
            request.setMethod('GET');
            request.setTimeout(10000); // 10 seconds timeout

            HttpResponse response = http.send(request);

            // Step 5: Handle the response
            if (response.getStatusCode() == 200) {
                // Parse the JSON response
                Map<String, Object> weatherData = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());               
                res.statusCode = 200;
                res.responseBody = Blob.valueOf(JSON.serialize(weatherData));
            } else {
                // Handle API errors
                res.statusCode = response.getStatusCode();
                res.responseBody = Blob.valueOf(JSON.serialize(new ErrorResponse('API Error', 'Failed to fetch weather data: ' + response.getStatus())));
            }
        } catch (QueryException e) {
            // Handle case where no Weather_Settings__mdt record is found
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(new ErrorResponse('Server Error', 'Weather API configuration not found')));
        } catch (Exception e) {
            // Handle unexpected errors
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(new ErrorResponse('Server Error', 'An error occurred: ' + e.getMessage())));
        }
    }

    // Error response wrapper
    private class ErrorResponse {
        public String error;
        public String message;

        public ErrorResponse(String error, String message) {
            this.error = error;
            this.message = message;
        }
    }

    // Placeholder for JWT validation (from Task 4)
    private static Boolean validateJWT(String jwtToken) {
        // Implement your JWT validation logic here
        // Return true if valid, false otherwise
        return true; // Replace with actual implementation
    }
}