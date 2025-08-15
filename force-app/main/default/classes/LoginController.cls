@RestResource(urlMapping='/login')
global without sharing class LoginController {

    @HttpPost
    global static String doLogin() {
        RestRequest req = RestContext.request;
        String body = req.requestBody.toString();
        Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(body);
        String username = (String) params.get('username');
        String password = (String) params.get('password');

        if (String.isBlank(username) || String.isBlank(password)) {
            throw new PasswordUtility.CustomException('Missing username or password', 400);
        }

        // Query user
        List<Ecommerce_User__c> users = [SELECT Id, Password__c, Salt__c FROM Ecommerce_User__c WHERE Name = :username LIMIT 1];
        if (users.isEmpty()) {
            throw new PasswordUtility.CustomException('Invalid credentials', 401);
        }

        // Verify password with salt
        String hashedInput = PasswordUtility.hashPasswordWithSalt(password, users[0].Salt__c);
        if (hashedInput != users[0].Password__c) {
            throw new PasswordUtility.CustomException('Invalid credentials', 401);
        }

        // Generate JWT
        String jwt = generateJWT(users[0].Id);

        return JSON.serialize(new Map<String, String>{ 'token' => jwt });
    }

    private static String generateJWT(String userId) {
        // Header
        String header = '{"alg":"HS256","typ":"JWT"}';
        String encodedHeader = base64UrlEncode(Blob.valueOf(header));

        // Payload
        Long iat = DateTime.now().getTime() / 1000;
        Long exp = iat + 3600; // 1 hour expiration
        String payload = JSON.serialize(new Map<String, Object>{
            'sub' => userId,
            'iat' => iat,
            'exp' => exp
        });
        String encodedPayload = base64UrlEncode(Blob.valueOf(payload));

        // Signing
        String signingData = encodedHeader + '.' + encodedPayload;
        String secret = [SELECT Secret_Key__c FROM JWT_Setting__mdt WHERE DeveloperName = 'Default' LIMIT 1].Secret_Key__c;
        Blob signature = Crypto.generateMac('HmacSHA256', Blob.valueOf(signingData), Blob.valueOf(secret));
        String encodedSignature = base64UrlEncode(signature);

        return signingData + '.' + encodedSignature;
    }

    private static String base64UrlEncode(Blob input) {
        return EncodingUtil.base64Encode(input).replaceAll('\\+', '-').replaceAll('/', '_').replaceAll('=+$', '');
    }
}