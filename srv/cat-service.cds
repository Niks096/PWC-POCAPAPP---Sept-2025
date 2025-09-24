using {
    pocap.db.master as master, pocap.db.transaction as transaction
} from '../db/datamodel';

using { pocap.common as c } from '../db/common';


service CatalogService @(path: 'CatalogService', requires: 'authenticated-user') {
    
    @Capabilities : { 
        InsertRestrictions : {
            $Type : 'Capabilities.InsertRestrictionsType',
            Insertable : true
        },
        UpdateRestrictions : {
            $Type : 'Capabilities.UpdateRestrictionsType',
            Updatable : true
        },
        DeleteRestrictions : {
            $Type : 'Capabilities.DeleteRestrictionsType',
            Deletable : false
        },
     }
    entity BusinessPartnerService as projection on master.businesspartner;

    // Apply restrictions 
    @readonly
    entity ProductInformation as projection on master.product;

    entity EmployeeDetails @(restrict : [
        {
            grant : ['Read'], to: 'Viewer', where: 'bankName = $user.bankName'
        },
        {
            grant : ['Write'], to: 'Admin'
        }
    ])
     as projection on master.employees;

    entity AddressInfo @(restrict : [
        {
            grant : ['Read'], to: 'Viewer', where: 'COUNTRY = $user.myCountry'
        },
        {
            grant : ['Write'], to: 'Admin'
        }
    ])as projection on master.address;

    entity PODetails @(
        odata.draft.enabled : true
    )     
    as projection on transaction.purchaseorder {
        *,
        case OVERALL_STATUS
            when 'N' then 'New'
            when 'P' then 'Paid'
            when 'B' then 'Blocked'
            when 'R' then 'Returned'
            else 'Delivered'
        end as OverallStatus : String(20) @(title: '{i18n>OVERALL_STATUS}'),

        case OVERALL_STATUS
            when 'N' then 3
            when 'P' then 2
            when 'B' then 1
            when 'R' then 3
            else 3
        end as OSCriticality : Integer,

        case LIFECYCLE_STATUS
            when 'N' then 'New'
            when 'I' then 'In Progress'
            when 'P' then 'Pending'
            when 'C' then 'Cancelled'
            else 'Done'
        end as LifecycleStatus : String(20) @(title: '{i18n>LIFECYCLE_STATUS}'),

        case LIFECYCLE_STATUS
            when 'N' then 3
            when 'P' then 2
            when 'B' then 1
            when 'R' then 3
            else 2
        end as LSCriticality : Integer,

        Items : redirected to POItems
    } actions {
        @cds.odata.bindingparameter.name : '_pricehike'
        @Common.SideEffects : {
            TargetProperties : [
                '_pricehike/GROSS_AMOUNT',
                '_pricehike/NET_AMOUNT',
                '_pricehike/TAX_AMOUNT'
            ],
         }

        action increasedPrice() returns array of PODetails;
        function largestOrder() returns array of PODetails;
    };

    entity POItems as projection on transaction.purchaseitems;

// Custom Action
    action createEmployee(
        // Import Parameters
        nameFirst : String(40),
        nameMiddle : String(40),
        nameLast : String(40),
        nameInitials : String(40),
        gender : c.Gender,
        language : String(2),
        phone : c.phoneNumber,
        email : c.Email,
       // Currency  : String(3),
        loginName : String(15),
        salaryAmount : c.AmountT,
        accountNumber : String(16),
        bankId : String(12),
        bankName : String(64)     
    )
    //Export Parameters
    returns array of String;

// Custom Function
    function getProducts(
        CURRENCY_CODE : String(3)
    ) returns array of ProductInformation;
}