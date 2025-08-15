@RestResource(urlMapping='/products/*')
global without sharing class ProductAPI {

    // Create a new product
    @HttpPost
    global static void createProduct() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        try {
            Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
            String name = (String) params.get('name');
            String description = (String) params.get('description');
            Decimal price = (Decimal) params.get('price');

            if (String.isBlank(name) || price == null) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{'error' => 'Name and price are required'}));
                return;
            }

            Product__c product = new Product__c(
                Name = name,
                Description__c = description,
                Price__c = price
            );
            insert product;

            res.statusCode = 201;
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{'id' => product.Id, 'message' => 'Product created successfully'}));
        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{'error' => 'Server error: ' + e.getMessage()}));
        }
    }


    // Get a single  / all Products
    @HttpGet
    global static void getProducts() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        try {            
            String productId = req.requestURI.substringAfterLast('/products/');
            system.debug('********* Product ID: ' + productId);

            if (String.isNotBlank(productId)) {
                // Retrieve specific product
                
                List<Product__c> products = [SELECT Id, Name, Description__c, Price__c, CreatedDate, LastModifiedDate 
                                            FROM Product__c 
                                            WHERE Id = :productId 
                                            LIMIT 1];
                system.debug('********* Product List: ' + products);
                if (products.isEmpty()) {
                    res.statusCode = 404;
                    res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{'error' => 'Product not found'}));
                    return;
                }
                // Prepare detailed response
                Product__c product = products[0];
                Map<String, Object> response = new Map<String, Object>{
                    'id' => product.Id,
                    'name' => product.Name,
                    'description' => product.Description__c,
                    'price' => product.Price__c,
                    'createdDate' => product.CreatedDate,
                    'lastModifiedDate' => product.LastModifiedDate
                };
                res.statusCode = 200;
                res.responseBody = Blob.valueOf(JSON.serialize(response));
            } else {
                // Retrieve all products
                List<Product__c> products = [SELECT Id, Name, Description__c, Price__c FROM Product__c];
                res.statusCode = 200;
                res.responseBody = Blob.valueOf(JSON.serialize(products));
            }
        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{'error' => 'Server error: ' + e.getMessage()}));
        }
    }

    // Update Product
    @HttpPatch
    global static void updateProduct() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        try {
            String productId = req.requestURI.substringAfterLast('/products/');
            if (String.isBlank(productId)) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{'error' => 'Product ID is required'}));
                return;
            }

            Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
            Product__c product = [SELECT Id, Name, Description__c, Price__c FROM Product__c WHERE Id = :productId LIMIT 1];
            if (product == null) {
                res.statusCode = 404;
                res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{'error' => 'Product not found'}));
                return;
            }

            if (params.containsKey('name')) product.Name = (String) params.get('name');
            if (params.containsKey('description')) product.Description__c = (String) params.get('description');
            if (params.containsKey('price')) product.Price__c = (Decimal) params.get('price');

            update product;

            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{'message' => 'Product updated successfully'}));
        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{'error' => 'Server error: ' + e.getMessage()}));
        }
    }

    // Delete Product
    @HttpDelete
    global static void deleteProduct() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        try {
            String productId = req.requestURI.substringAfterLast('/products/');
            if (String.isBlank(productId)) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{'error' => 'Product ID is required'}));
                return;
            }

            Product__c product = [SELECT Id FROM Product__c WHERE Id = :productId LIMIT 1];
            if (product == null) {
                res.statusCode = 404;
                res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{'error' => 'Product not found'}));
                return;
            }

            delete product; 
            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{'message' => 'Product deleted successfully'}));
        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{'error' => 'Server error: ' + e.getMessage()}));
        }
    }
}