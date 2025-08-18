trigger OrderProductTrigger on Order_Product__c (after insert, after update, after delete, after undelete) {
    Set<Id> orderIds = new Set<Id>();
    
    // Collect Order__c IDs from triggered records
    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        for (Order_Product__c op : Trigger.new) {
            if (op.Order__c != null) {
                orderIds.add(op.Order__c);
            }
        }
    }
    if (Trigger.isDelete) {
        for (Order_Product__c op : Trigger.old) {
            if (op.Order__c != null) {
                orderIds.add(op.Order__c);
            }
        }
    }
    
    // Process only if there are Order__c records to update
    if (!orderIds.isEmpty()) {
        List<Order__c> ordersToUpdate = new List<Order__c>();
        // Aggregate Subtotal__c for each Order__c with decimal precision
        AggregateResult[] aggregatedResults = [SELECT Order__c, SUM(Subtotal__c) total 
                                             FROM Order_Product__c 
                                             WHERE Order__c IN :orderIds 
                                             GROUP BY Order__c];
        
        // Map to store the aggregated totals with decimal precision
        Map<Id, Decimal> orderTotalMap = new Map<Id, Decimal>();
        for (AggregateResult ar : aggregatedResults) {
            Decimal total = (Decimal)ar.get('total');
            orderTotalMap.put((Id)ar.get('Order__c'), total != null ? total.setScale(2) : 0); // Set to 2 decimal places
        }
        
        // Prepare orders for update
        for (Id orderId : orderIds) {
            Decimal totalSubtotal = orderTotalMap.containsKey(orderId) ? orderTotalMap.get(orderId) : 0;
            ordersToUpdate.add(new Order__c(Id = orderId, Total_Price__c = totalSubtotal));
        }
        
        // Update the Orders
        if (!ordersToUpdate.isEmpty()) {
            update ordersToUpdate;
        }
    }
}