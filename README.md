# HelloID-Conn-Prov-Source-Anthology-CampusNexus

| :information_source: Information |
|:---------------------------|
| This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.       |
<br />
<p align="center">
 <img src="https://github.com/Tools4everBV/HelloID-Conn-Prov-Source-PowerSchool-SIS-Students/assets/24281600/2defdc40-c598-4198-a016-259a26c9040d">
</p>
<br />
HelloID Provisioning Source Connector for Anthology CampusNexus


<!-- TABLE OF CONTENTS -->
## Table of Contents
* [Getting Started](#getting-started)
* [Setting up the API access](#setting-up-the-api-access)
* [Configuration](#configuration)

<!-- GETTING STARTED -->
## Getting Started
By using this connector you will have the ability to import data into HelloID:

* Student Demographics
* Student Enrollment Periods

## Setting up the API Access
The purpose of this is to provide steps on generating and using key based authentication for Student Rest APIs

* Introduction 
The Application API Keys configuration is enhanced to be used when authenticating to the entire Student REST API set instead of only being used for the Campuslink APIs. 

This enhancement:
    * Limits the integrating partners to only access the modules to which they have permissions. Appropriate audits will be recorded in the database. 
    * Allows the integrating partner to generate their own application key, associated to a user in the Staff entity. 

* Steps
    * Location - Select Settings > System > Application API Keys.
  
    ![image](https://github.com/Tools4ever-NIM/NIM-System-REST-Campus-Nexus/assets/24281600/049b9163-5b3e-487c-9a08-bb5168c6303c)
    ![image](https://github.com/Tools4ever-NIM/NIM-System-REST-Campus-Nexus/assets/24281600/396c515a-bc96-401e-beda-996512ebd939)

    * Product Help Link      
    https://help.campusmanagement.com/CNS/23.0/WebClient/Content/SU/System/ApplicationAPIK

    * Encode the Application with Base 64
    https://www.base64encode.org/ 
 
    `{"CallingAppName":"DualEnrollAPI","KeyValue":"YsIQkq2Hj/viKSM5Lzn07Q=="} `

        * CallingAppName: Calling Application Name 
        * KeyValue: Application Key 

    Encode the value and share it with client/vendor
    
    ![image](https://github.com/Tools4ever-NIM/NIM-System-REST-Campus-Nexus/assets/24281600/faf2abed-b9ed-4826-a573-a1e2ddb11b6c)

    Client/Vendor can use the encoded value with “ApplicationKey encoded value

    ![image](https://github.com/Tools4ever-NIM/NIM-System-REST-Campus-Nexus/assets/24281600/2d65f251-d756-4fcc-82d5-8b20bf315712)


## Configuration
1. Add a new 'Source System' to HelloID and make sure to import all the necessary files.

    - [ ] configuration.json
    - [ ] person.ps1

2. Fill in the required fields on the 'Configuration' tab. See also, [Setting up the API access](#setting-up-the-api-access)

* Base URI
  * URL of Instance
* Page Size
* Application Key
* Student Fields
* Statuses Included
* Shifts Excluded

_For more information about our HelloID PowerShell connectors, please refer to our general [Documentation](https://docs.helloid.com/hc/en-us/articles/360012557600-Configure-a-custom-PowerShell-source-system) page_

# HelloID Docs
The official HelloID documentation can be found at: https://docs.helloid.com/
