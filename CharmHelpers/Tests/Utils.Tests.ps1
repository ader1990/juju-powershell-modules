#ps1_sysnative

# Copyright 2014 Cloudbase Solutions Srl
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

$moduleName = "utils"
$modulePath = Resolve-Path "..\utils.psm1"
Import-Module $modulePath -DisableNameChecking

InModuleScope $moduleName {
    Describe "Merge Left" {
        Context "It should succeed" {
            $first =@{
                "rabbit_host"="host";
                "rabbit_password"="pass";
            }

            $second =@{
                "rabbit_host"="host_changed";
                "rabbit_password_1"="pass_1";
            }

            $expectedResult =@{
                "rabbit_host"="host_changed";
                "rabbit_password"="pass";
                "rabbit_password_1"="pass_1";
            }

            $result = MergeLeft-Array $first $second

            It "should verify result" {
                (Compare-HashTables $result $expectedResult)| Should Be $true
            }
        }
    }

    Describe "Update-IniEntry" {
        Context "It should succeed" {
            $fakeContent = "fakeContent"
            $fakePath = "fakePath"
            $fakeName = "fakeName"
            $fakeValue = "fakeValue"

            Mock Get-Content { return $fakeContent } -Verifiable
            Mock Set-Content { return } -Verifiable

            $result = Update-IniEntry $fakePath $fakeName $fakeValue

            It "should verify all methods are called" {
                    Assert-VerifiableMocks
                }
            }
    }

}

Remove-Module $moduleName