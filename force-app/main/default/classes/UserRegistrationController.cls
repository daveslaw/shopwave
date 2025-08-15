@RestResource(urlMapping='/register')
global without sharing class UserRegistrationController {
    @HttpPost
    global static String doRegister() {
        RestRequest req = RestContext.request;
        String body = req.requestBody.toString();
        Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(body);
        String username = (String) params.get('username');
        String email = (String) params.get('email');
        String password = (String) params.get('password');

        if (String.isBlank(username) || String.isBlank(email) || String.isBlank(password)) {
            throw new PasswordUtility.CustomException('Missing required fields', 400);
        }

        // Check if username exists
        if ([SELECT Count() FROM Ecommerce_User__c WHERE Name = :username] > 0) {
            throw new PasswordUtility.CustomException('Username already taken', 409);
        }

        // Hash password with salt
        Map<String, String> passwordData = PasswordUtility.hashPassword(password);

        // Create user
        Ecommerce_User__c user = new Ecommerce_User__c(
            Name = username,
            Email__c = email,
            Password__c = passwordData.get('hash'),
            Salt__c = passwordData.get('salt')
        );
        insert user;

        return JSON.serialize(new Map<String, String>{ 'message' => 'User registered successfully', 'userId' => user.Id });
    }
}