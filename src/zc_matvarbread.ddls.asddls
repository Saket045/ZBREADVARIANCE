@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@EndUserText: {
  label: '###GENERATED Core Data Service Entity'
}
@ObjectModel: {
  sapObjectNodeType.name: 'ZMATVARBREAD'
}
@AccessControl.authorizationCheck: #NOT_REQUIRED
define root view entity ZC_MATVARBREAD
  provider contract transactional_query
  as projection on ZR_MATVARBREAD
{
  key CompCode,
  key PlantCode,
  key Bomcomponentcode,
  key Bomcomponentname,
  key Productionorder,
  key Actualconsumption,
  key Shift,
  @Consumption: {
    valueHelpDefinition: [ {
      entity.element: 'UnitOfMeasure', 
      entity.name: 'I_UnitOfMeasureStdVH', 
      useForValidation: true
    } ]
  }
  key Confirmationyieldquantity,
  Confirmationdate,
  Confirmationtime,
  Postingdate,
  Creationdate,
  WorkCenter,
  Product,
  Productdesc,
  Bomcomponentrequiredquantity,
  Goodsmovementtype,
  @Consumption: {
    valueHelpDefinition: [ {
      entity.element: 'Currency', 
      entity.name: 'I_CurrencyStdVH', 
      useForValidation: true
    } ]
  }
  Bomamtcurr,
  @Semantics: {
    amount.currencyCode: 'Bomamtcurr'
  }
  Actualcost,
  Qtydiff,
  @Semantics: {
    amount.currencyCode: 'Bomamtcurr'
  }
  Amtdiff,
  @Semantics: {
    amount.currencyCode: 'Bomamtcurr'
  }
  Amtdiffactualrate,
  @Semantics: {
    amount.currencyCode: 'Bomamtcurr'
  }
  Bomcomponentamt,
  @Semantics: {
    user.createdBy: true
  }
  CreatedBy,
  @Semantics: {
    systemDateTime.createdAt: true
  }
  CreatedAt,
  @Semantics: {
    user.localInstanceLastChangedBy: true
  }
  LastChangedBy,
  @Semantics: {
    systemDateTime.localInstanceLastChangedAt: true
  }
  LastChangedAt,
  @Semantics: {
    systemDateTime.lastChangedAt: true
  }
  LocalLastChangedAt
}
