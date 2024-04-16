
# HelloID-Conn-Prov-Target-CSV

> [!IMPORTANT]
> This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.

<p align="center">
  <img src="https://github.com/Tools4everBV/HelloID-Conn-Prov-Target-CSV/blob/main/Logo.png?raw=true">
</p>

## Table of contents

- [HelloID-Conn-Prov-Target-CSV](#helloid-conn-prov-target-csv)
  - [Table of contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Remarks](#remarks)
  - [Introduction](#introduction)
  - [Getting started](#getting-started)
    - [Provisioning PowerShell V2 connector](#provisioning-powershell-v2-connector)
      - [Correlation configuration](#correlation-configuration)
      - [Field mapping](#field-mapping)
    - [Connection settings](#connection-settings)
  - [Getting help](#getting-help)
  - [HelloID docs](#helloid-docs)

## Prerequisites
- [ ] _HelloID_ on-prem Provisioning agent.
- [ ] _HelloID_ environment.
- [ ] Existing CSV file. HelloID **won't** create a new file if it doesn't exist.
- [ ] **Concurrent sessions** in HelloID set to a **maximum of 1**! Exceeding this limit may result in file locking.

## Remarks
- This connector is designed to support only one object per person. If there's a need for more objects per person or per contract of a person, adjustments should be made accordingly.

## Introduction
_HelloID-Conn-Prov-Target-CSV_ is a _target_ connector. _Microsoft_ provides a the module _Microsoft.PowerShell.Utility_ by default in all PowerShell versions that allow you to programmatically interact with CSV data. This connector uses the cmdlets listed in the table below.

| Cmdlet                                                                                                    | Description                                                                                              |
| --------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| [Import-CSV](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/import-csv) | Create table-like custom objects from the items in a character-separated value (CSV) file                |
| [Export-CSV](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/export-csv) | Convert objects into a series of character-separated value (CSV) strings and saves the strings to a file |


The following lifecycle actions are available:

| Action             | Description                       |
| ------------------ | --------------------------------- |
| create.ps1         | Create or correlate to row in CSV |
| delete.ps1         | Delete row in CSV                 |
| update.ps1         | Update row in CSV                 |
| configuration.json | Default _configuration.json_      |
| fieldMapping.json  | Default _fieldMapping.json_       |

## Getting started
By using this connector you will have the ability to seamlessly create, update and delete rows in a CSV. 
> Please ensure that you've created the CSV file beforehand, as HelloID **will not** generate a new file if it doesn't exist.

### Provisioning PowerShell V2 connector

#### Correlation configuration
The correlation configuration is used to specify which properties will be used to match an existing row within the _CSV_ to a person in _HelloID_.

To properly setup the correlation:

1. Open the `Correlation` tab.

2. Specify the following configuration:

    | Setting                   | Value        |
    | ------------------------- | ------------ |
    | Enable correlation        | `True`       |
    | Person correlation field  | ``           |
    | Account correlation field | `EmployeeId` |

> [!TIP]
> _For more information on correlation, please refer to our correlation [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems/correlation.html) pages_.

#### Field mapping
The field mapping can be imported by using the _fieldMapping.json_ file.

### Connection settings
The following settings are required to connect to the API.

| Setting       | Description                                                                                                                  | Mandatory |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------- | --------- |
| CSV File Path | The path to the CSV file to export the data to.                                                                              | Yes       |
| Delimiter     | The delimiter that separates the property values in the CSV file. The default is a comma (,).                                | Yes       |
| Encoding      | The encoding for the imported CSV file. The default value is utf8.                                                           | No        |
| IsDebug       | When toggled, extra logging is shown. Note that this is only meant for debugging, please switch this off when in production. | No        |

## Getting help
> [!TIP]
> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems.html) pages_. 

> [!TIP]
>  _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_.

## HelloID docs
The official HelloID documentation can be found at: https://docs.helloid.com/