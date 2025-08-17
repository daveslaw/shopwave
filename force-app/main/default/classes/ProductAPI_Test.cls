@isTest
private class ProductAPI_Test {
    
    // Setup method to create test data
    @TestSetup
    static void setup() {
        // Create test user for JWT
        Ecommerce_User__c user = new Ecommerce_User__c(
            Name = 'testuser',
            Email__c = 'test@example.com',
            Password__c = 'hashedpassword',
            Salt__c = 'testsalt'
        );
        insert user;

        // Create test products
        Product__c product1 = new Product__c(
            Name = 'Test Product 1',
            Description__c = 'Test Description',
            Price__c = 99.99
        );
        insert product1;

        Product__c product2 = new Product__c(
            Name = 'Test Product 2',
            Description__c = 'Test Description',
            Price__c = 199.99
        );
        insert product2;

        // Note: In a real environment, mock JWT_Setting__mdt or deploy custom metadata
        // For testing, we assume JWT_Setting__mdt exists with a secret key
    }

    // Helper method to generate a valid JWT for testing
    private static String generateTestJWT(String userId) {
        String header = '{"alg":"HS256","typ":"JWT"}';
        String encodedHeader = EncodingUtil.base64Encode(Blob.valueOf(header)).replaceAll('\\+', '-').replaceAll('/', '_').replaceAll('=+$', '');
        
        Long iat = DateTime.now().getTime() / 1000;
        Long exp = iat + 3600;
        String payload = JSON.serialize(new Map<String, Object>{
            'sub' => userId,
            'iat' => iat,
            'exp' => exp
        });
        String encodedPayload = EncodingUtil.base64Encode(Blob.valueOf(payload)).replaceAll('\\+', '-').replaceAll('/', '_').replaceAll('=+$', '');
        
        String signingData = encodedHeader + '.' + encodedPayload;
        String secret = 'test_secret_key'; // Mock secret; in production, ensure JWT_Setting__mdt is queried or mocked
        Blob signature = Crypto.generateMac('HmacSHA256', Blob.valueOf(signingData), Blob.valueOf(secret));
        String encodedSignature = EncodingUtil.base64Encode(signature).replaceAll('\\+', '-').replaceAll('/', '_').replaceAll('=+$', '');
        
        return signingData + '.' + encodedSignature;
    }

    // Test createProduct success scenario
    @isTest
    static void testCreateProductSuccess() {
        // Arrange
        Ecommerce_User__c user = [SELECT Id FROM Ecommerce_User__c WHERE Name = 'testuser' LIMIT 1];
        String jwt = generateTestJWT(user.Id);
        
        Map<String, Object> requestBody = new Map<String, Object>{
            'name' => 'New Product',
            'description' => 'New Description',
            'price' => 49.99
        };
        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/products/';
        req.httpMethod = 'POST';
        req.addHeader('X-Auth-Token', jwt);
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Act
        Test.startTest();
        ProductAPI.createProduct();
        Test.stopTest();

        // Assert
        RestResponse res = RestContext.response;
        System.assertEquals(201, res.statusCode, 'Status code should be 201');
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertNotEquals(null, responseBody.get('id'), 'Response should contain product ID');
        System.assertEquals('Product created successfully', responseBody.get('message'), 'Success message incorrect');
        
        Product__c product = [SELECT Id, Name, Description__c, Price__c FROM Product__c WHERE Id = :String.valueOf(responseBody.get('id'))];
        System.assertEquals('New Product', product.Name, 'Product name incorrect');
        System.assertEquals('New Description', product.Description__c, 'Product description incorrect');
        System.assertEquals(49.99, product.Price__c, 'Product price incorrect');
    }

    // Test createProduct missing required fields
    @isTest
    static void testCreateProductMissingFields() {
        // Arrange
        Ecommerce_User__c user = [SELECT Id FROM Ecommerce_User__c WHERE Name = 'testuser' LIMIT 1];
        String jwt = generateTestJWT(user.Id);
        
        Map<String, Object> requestBody = new Map<String, Object>{
            'description' => 'No Name or Price'
        };
        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/products/';
        req.httpMethod = 'POST';
        req.addHeader('X-Auth-Token', jwt);
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Act
        Test.startTest();
        ProductAPI.createProduct();
        Test.stopTest();

        // Assert
        RestResponse res = RestContext.response;
        System.assertEquals(400, res.statusCode, 'Status code should be 400');
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('Name and price are required', responseBody.get('error'), 'Error message incorrect');
    }

    // Test createProduct invalid JWT
    @isTest
    static void testCreateProductInvalidJWT() {
        // Arrange
        Map<String, Object> requestBody = new Map<String, Object>{
            'name' => 'New Product',
            'description' => 'New Description',
            'price' => 49.99
        };
        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/products/';
        req.httpMethod = 'POST';
        req.addHeader('X-Auth-Token', 'invalid.jwt.token');
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Act
        Test.startTest();
        try {
            ProductAPI.createProduct();
            System.assert(false, 'Expected CustomException was not thrown');
        } catch (PasswordUtility.CustomException e) {
            System.assertEquals('Invalid JWT format', e.getMessage(), 'Exception message incorrect');
            System.assertEquals(401, e.statusCode, 'Exception status code should be 401');
        }
        Test.stopTest();

        // Assert
        RestResponse res = RestContext.response;
        System.assertEquals(401, res.statusCode, 'Status code should be 401');
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('Invalid JWT format', responseBody.get('message'), 'Error message incorrect');
    }

    // Test getProducts retrieve all products
    @isTest
    static void testGetAllProducts() {
        // Arrange
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/products/';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Act
        Test.startTest();
        ProductAPI.getProducts();
        Test.stopTest();

        // Assert
        RestResponse res = RestContext.response;
        System.assertEquals(200, res.statusCode, 'Status code should be 200');
        List<Object> responseBody = (List<Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals(2, responseBody.size(), 'Should return two products');
        
        // Verify both products
        Set<String> productNames = new Set<String>();
        for (Object obj : responseBody) {
            Map<String, Object> product = (Map<String, Object>) obj;
            productNames.add((String) product.get('Name'));
            System.assertEquals('Test Description', product.get('Description__c'), 'Product description incorrect');
        }
        System.assert(productNames.contains('Test Product 1'), 'Test Product 1 should be in response');
        System.assert(productNames.contains('Test Product 2'), 'Test Product 2 should be in response');
    }

    // Test getProducts retrieve specific product
    @isTest
    static void testGetSingleProduct() {
        // Arrange
        Product__c product = [SELECT Id FROM Product__c WHERE Name = 'Test Product 1' LIMIT 1];
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/products/' + product.Id;
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Act
        Test.startTest();
        ProductAPI.getProducts();
        Test.stopTest();

        // Assert
        RestResponse res = RestContext.response;
        System.assertEquals(200, res.statusCode, 'Status code should be 200');
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals(product.Id, responseBody.get('id'), 'Product ID incorrect');
        System.assertEquals('Test Product 1', responseBody.get('name'), 'Product name incorrect');
        System.assertEquals('Test Description', responseBody.get('description'), 'Product description incorrect');
        System.assertEquals(99.99, responseBody.get('price'), 'Product price incorrect');
    }

    // Test getProducts product not found
    @isTest
    static void testGetProductNotFound() {
        // Arrange
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/products/invalidId';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Act
        Test.startTest();
        ProductAPI.getProducts();
        Test.stopTest();

        // Assert
        RestResponse res = RestContext.response;
        System.assertEquals(404, res.statusCode, 'Status code should be 404');
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('Product not found', responseBody.get('error'), 'Error message incorrect');
    }
}