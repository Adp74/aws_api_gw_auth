ENV = "DEV"

api_gw_resources_and_methods = {
      "resource1" = {
            "path"                 = "cognito"   
            "methods"              =  ["POST"]
            "method_authorization" = ["COGNITO_USER_POOLS"]
      },
      "resource2" = {
            "path"                 = "resource2"   
            "methods"              =  ["POST"]
            "method_authorization" = ["COGNITO_USER_POOLS"]
      }

}